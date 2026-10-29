import Foundation
import Combine

@MainActor
final class OBDService: ObservableObject {
    @Published private(set) var state: OBDSessionState = .idle
    @Published private(set) var vehicleData = VehicleData()
    @Published private(set) var supportedPIDs: Set<UInt8> = []
    @Published private(set) var updatedAt: [UInt8: Date] = [:]

    private let bluetoothManager: BluetoothManager
    private var responseBuffer = ""
    private var currentCommand: String?
    private var commands: [String] = []
    private var timeoutTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private enum Phase { case configuration, capabilities, initialRead, polling }
    private var phase = Phase.configuration

    // Only the three existing product readings are polled. RPM is not a feature.
    private let readingPIDs: [UInt8] = [0x05, 0x2F, 0x42]

    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        bluetoothManager.onTextReceived = { [weak self] text in self?.receive(text) }
        bluetoothManager.onConnectionLost = { [weak self] in self?.stopSession() }
    }

    // MARK: - Session Lifecycle

    func startSession() {
        guard bluetoothManager.state == .connected else { return }
        stopSession()
        state = .initializing
        phase = .configuration
        // Adapter setup and read requests only. No fault clearing or coding commands.
        commands = ["ATZ", "ATE0", "ATL0", "ATS0", "ATH0", "ATSP0"]
        sendNextCommand()
    }

    func stopSession() {
        timeoutTask?.cancel()
        pollingTask?.cancel()
        commands = []
        currentCommand = nil
        responseBuffer = ""
        vehicleData = VehicleData()
        supportedPIDs = []
        updatedAt = [:]
        state = .idle
    }

    private func fail(_ message: String) {
        // Disconnect after a timeout: a late response must not satisfy a new command.
        stopSession()
        bluetoothManager.disconnect()
        state = .failed(message)
    }

    // MARK: - Serialized Command Queue

    private func sendNextCommand() {
        guard currentCommand == nil else { return }
        guard !commands.isEmpty else {
            advancePhase()
            return
        }
        let command = commands.removeFirst()
        currentCommand = command
        let wait: Double = command == "0100" ? 25 : 10
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(wait)) } catch { return }
            guard !Task.isCancelled, let self, self.currentCommand == command else { return }
            self.fail("الجهاز لم يرسل ردًا في الوقت المحدد. تأكد من تركيبه وتشغيل إشعال السيارة، ثم أعد الاتصال.")
        }
        guard bluetoothManager.send(command: command) else {
            fail("تعذر إرسال الطلب إلى جهاز القراءة. أعد الاتصال بالجهاز.")
            return
        }
    }

    private func advancePhase() {
        switch phase {
        case .configuration:
            phase = .capabilities
            state = .checkingVehicle
            commands = ["0100"]
            sendNextCommand()
        case .capabilities:
            phase = .initialRead
            commands = readingCommands
            sendNextCommand()
        case .initialRead:
            // A valid vehicle support bitmap has been received before this point.
            // This remains a verified connection even if all three values are unavailable.
            phase = .polling
            state = .ready
            startPolling()
        case .polling:
            break
        }
    }

    private var readingCommands: [String] {
        readingPIDs.filter { supportedPIDs.contains($0) }.map { String(format: "01%02X", $0) }
    }

    // MARK: - Fragmented Responses

    private func receive(_ text: String) {
        guard currentCommand != nil else { return }
        responseBuffer += text
        guard responseBuffer.count < 16_384 else {
            fail("وصل رد غير متوقع من الجهاز. أعد الاتصال.")
            return
        }
        while let prompt = responseBuffer.firstIndex(of: ">") {
            let response = String(responseBuffer[..<prompt])
            responseBuffer.removeSubrange(...prompt)
            processResponse(response)
        }
    }

    private func processResponse(_ response: String) {
        guard let command = currentCommand else { return }
        timeoutTask?.cancel()
        currentCommand = nil
        let upper = response.uppercased()
        let errors = ["UNABLE TO CONNECT", "CAN ERROR", "BUS ERROR", "BUS INIT: ERROR", "STOPPED"]
        if errors.contains(where: { upper.contains($0) }) {
            fail("وصلنا إلى جهاز القراءة، لكن تعذر التواصل مع السيارة. تحقق من إشعالها وتوافقها مع OBD-II.")
            return
        }

        if command.hasPrefix("AT") {
            let valid = command == "ATZ"
                ? (upper.contains("ELM") || upper.contains("STN") || upper.contains("OBDLINK"))
                : lines(in: upper).contains("OK")
            guard valid else {
                fail("الجهاز المختار لم يستجب كجهاز قراءة متوافق. اختر جهاز LELink وتأكد من إعداداته.")
                return
            }
        } else if phase == .capabilities {
            let base = Int(command.suffix(2), radix: 16) ?? 0
            let replies = payloads(for: UInt8(base), in: upper).filter { $0.count >= 4 }
            guard !replies.isEmpty else {
                fail("تم الاتصال بالجهاز، لكن لم نستقبل تأكيدًا من كمبيوتر السيارة. تحقق من الإشعال والتوافق ثم أعد المحاولة.")
                return
            }
            // Union the supported PIDs reported by the responding control units.
            var bitmap: UInt32 = 0
            for bytes in replies {
                bitmap |= bytes.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            }
            for offset in 1...32 where bitmap & (UInt32(1) << (32 - offset)) != 0 {
                supportedPIDs.insert(UInt8(base + offset))
            }
            // Only query the ranges needed for coolant, fuel level, and module voltage.
            if base < 0x40, bitmap & 1 != 0 {
                commands.append(String(format: "01%02X", base + 0x20))
            }
        } else {
            let pid = UInt8(command.suffix(2), radix: 16) ?? 0
            updateReading(pid: pid, bytes: payloads(for: pid, in: upper).first ?? [])
        }
        sendNextCommand()
    }

    private func lines(in response: String) -> [String] {
        response.components(separatedBy: .newlines).map {
            $0.filter { !$0.isWhitespace }.replacingOccurrences(of: "SEARCHING...", with: "")
        }
    }

    private func payloads(for pid: UInt8, in response: String) -> [[UInt8]] {
        let marker = String(format: "41%02X", pid)
        return lines(in: response).compactMap { line in
            guard line.hasPrefix(marker) else { return nil }
            let hex = Array(line.dropFirst(marker.count))
            guard hex.count.isMultiple(of: 2) else { return nil }
            var bytes: [UInt8] = []
            for index in stride(from: 0, to: hex.count, by: 2) {
                guard let byte = UInt8(String(hex[index...index + 1]), radix: 16) else { return nil }
                bytes.append(byte)
            }
            return bytes
        }
    }

    // MARK: - Physical Values and Availability

    private func updateReading(pid: UInt8, bytes: [UInt8]) {
        var received = false
        switch pid {
        case 0x05:
            vehicleData.coolantTemperature = bytes.first.map { Double(Int($0) - 40) }
            received = !bytes.isEmpty
        case 0x2F:
            vehicleData.fuelLevel = bytes.first.map { Double($0) * 100 / 255 }
            received = !bytes.isEmpty
        case 0x42:
            vehicleData.batteryVoltage = bytes.count >= 2
                ? Double(Int(bytes[0]) * 256 + Int(bytes[1])) / 1000 : nil
            received = bytes.count >= 2
        default:
            break
        }
        // Missing/invalid/NO DATA replies clear the old value instead of displaying it as live.
        updatedAt[pid] = received ? Date() : nil
    }

    private func startPolling() {
        pollingTask?.cancel()
        guard !readingCommands.isEmpty else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                guard !Task.isCancelled, let self, self.state == .ready else { return }
                guard self.currentCommand == nil else { continue }
                self.commands = self.readingCommands
                self.sendNextCommand()
            }
        }
    }
}
