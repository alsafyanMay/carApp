import Foundation
import Combine

@MainActor
final class OBDService: ObservableObject {
    @Published private(set) var state: OBDSessionState = .idle
    @Published private(set) var vehicleData = VehicleData.load() ?? VehicleData()
    @Published private(set) var supportedPIDs: Set<UInt8> = []
    @Published private(set) var updatedAt: [UInt8: Date] = [:]
    // 🆕 رقم هيكل السيارة (VIN) — nil لو السيارة ما أعطته
    @Published private(set) var vin: String?

    private let bluetoothManager: BluetoothManager
    private var responseBuffer = ""
    private var currentCommand: String?
    private var commands: [String] = []
    private var timeoutTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private enum Phase { case configuration, capabilities, initialRead, polling }
    private var phase = Phase.configuration

    private var capabilitiesRetryCount = 0

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
        capabilitiesRetryCount = 0
        #if targetEnvironment(simulator)
        state = .checkingVehicle
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.supportedPIDs = [0x05, 0x2F, 0x42]
            // 🆕 رقم هيكل تجريبي (تويوتا) للمحاكي
            self?.vin = "JTDBR32E720123456"
            self?.vehicleData = VehicleData(coolantTemperature: 89, fuelLevel: 72, batteryVoltage: 12.8, rpm: 800, lastRecordedAt: Date())
            self?.vehicleData.save()
            self?.state = .ready
        }
        #else
        state = .initializing
        phase = .configuration
        // أوامر تهيئة LELink / ELM327 الأساسية
        commands = ["ATZ", "ATE0", "ATL0", "ATH0", "ATSP0"]
        sendNextCommand()
        #endif
    }

    func stopSession() {
        timeoutTask?.cancel()
        pollingTask?.cancel()
        commands = []
        currentCommand = nil
        responseBuffer = ""
        capabilitiesRetryCount = 0
        // نحتفظ بآخر قراءة مسجلة لتبقى متاحة للمستخدم دون اتصال
        if vehicleData.lastRecordedAt == nil, let cached = VehicleData.load() {
            vehicleData = cached
        }
        supportedPIDs = []
        updatedAt = [:]
        vin = nil
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
            // إذا لم يتم استلام خريطة PIDs صريحة، نضع القراءات الأساسية كاحتياط
            if supportedPIDs.isEmpty {
                supportedPIDs = Set(readingPIDs)
            }
            // 🆕 نطلب رقم الهيكل (0902) أول، وبعدها القراءات
            commands = ["0902"] + readingCommands
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

    // ⭐ تعديل: نسأل عن القراءات الثلاث دايمًا، حتى لو السيارة ما أعلنت إنها تدعمها.
    // بعض السيارات (خصوصًا تويوتا) ما تذكر الوقود (2F) في قائمة الدعم مع إنها ترد عليه.
    // لو ما ردّت السيارة (NO DATA) تبقى القيمة السابقة، وما يتأثر الاتصال.
    private var readingCommands: [String] {
        readingPIDs.map { String(format: "01%02X", $0) }
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
        #if DEBUG
        // للتشخيص: نطبع رد الجهاز الخام لكل أمر (ابحثي في الكونسول عن "OBD>")
        print("OBD> \(command) ←", upper.replacingOccurrences(of: "\r", with: "⏎").replacingOccurrences(of: "\n", with: "⏎"))
        #endif
        let errors = ["UNABLE TO CONNECT", "CAN ERROR", "BUS ERROR", "BUS INIT: ERROR", "STOPPED"]
        if errors.contains(where: { upper.contains($0) }) {
            fail("تم الاتصال بقطعة الفحص، لكن تعذر التواصل مع كمبيوتر السيارة. تأكد أن سويتش السيارة في وضع التشغيل (Ignition ON) وليس فقط وضع الملحقات (ACC).")
            return
        }

        if command.hasPrefix("AT") {
            if command == "ATZ" {
                // نمنح LELink وقتاً للاستقرار بعد إعادة التشغيل
                Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(600))
                    self?.sendNextCommand()
                }
                return
            }
            // لأي أمر AT آخر: ننتقل مباشرة للأمر التالي دون شرط صارم يعيق الاتصال
            sendNextCommand()
            return
        } else if phase == .capabilities {
            let base = Int(command.suffix(2), radix: 16) ?? 0
            let replies = payloads(for: UInt8(base), in: upper).filter { $0.count >= 4 }
            if replies.isEmpty {
                // ⭐ تعديل: نعيد المحاولة ونفشل الاتصال فقط لو كان الأمر الأول (0100).
                // لو ما ردّت السيارة على 0120 أو 0140 نكمل عادي بدل ما نقطع الاتصال كامل.
                guard command == "0100" else {
                    sendNextCommand()
                    return
                }
                if capabilitiesRetryCount < 2 {
                    capabilitiesRetryCount += 1
                    commands.insert("0100", at: 0)
                    Task { [weak self] in
                        try? await Task.sleep(for: .seconds(1))
                        self?.sendNextCommand()
                    }
                    return
                } else {
                    fail("تم الاتصال بقطعة الفحص بنجاح، لكن كمبيوتر السيارة لم يستجب. تأكد من تشغيل سويتش السيارة بالكامل (Ignition ON) ليعمل كمبيوتر المحرك.")
                    return
                }
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
        } else if command == "0902" {
            // 🆕 رد رقم الهيكل (لو السيارة ما تدعمه يرجع nil ونكمل عادي)
            vin = parseVIN(upper)
        } else {
            let pid = UInt8(command.suffix(2), radix: 16) ?? 0
            updateReading(pid: pid, bytes: payloads(for: pid, in: upper).first ?? [])
        }
        sendNextCommand()
    }

    // 🆕 نطلع رقم الهيكل من رد 0902
    // الرد يجي على أكثر من سطر، مثلًا (CAN):
    //   014
    //   0:490201 4A5444
    //   1:424B5246 4B3330
    //   2:30313233 343536
    // أو (السيارات الأقدم) كل سطر يبدأ بـ 4902 ورقم ترتيبه.
    private func parseVIN(_ response: String) -> String? {
        var data: [UInt8] = []
        for rawLine in lines(in: response) {
            var line = rawLine
            // نشيل رقم الإطار في أول السطر (مثل "0:" أو "1:")
            if let colon = line.firstIndex(of: ":") { line = String(line[line.index(after: colon)...]) }
            // نتجاهل سطر الطول (مثل "014") وأي سطر مو أرقام هيكس زوجية
            guard !line.isEmpty, line.count.isMultiple(of: 2),
                  line.allSatisfy({ $0.isHexDigit }) else { continue }
            // نحوّل السطر لبايتات
            var bytes: [UInt8] = []
            var index = line.startIndex
            while index < line.endIndex {
                let next = line.index(index, offsetBy: 2)
                guard let byte = UInt8(line[index..<next], radix: 16) else { break }
                bytes.append(byte)
                index = next
            }
            // لو السطر يبدأ بـ 49 02 نشيلها مع رقم الترتيب اللي بعدها
            if bytes.count >= 3, bytes[0] == 0x49, bytes[1] == 0x02 { bytes.removeFirst(3) }
            data += bytes
        }
        // نخلي الحروف والأرقام الإنجليزية الكبيرة بس (الـ VIN ما فيه غيرها)
        let characters = data.filter { (0x30...0x39).contains($0) || (0x41...0x5A).contains($0) }
        let text = String(decoding: characters, as: UTF8.self)
        // الـ VIN دايمًا 17 خانة
        return text.count >= 17 ? String(text.suffix(17)) : nil
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
            if let temp = bytes.first.map({ Double(Int($0) - 40) }) {
                vehicleData.coolantTemperature = temp
                received = true
            }
        case 0x2F:
            if let fuel = bytes.first.map({ Double($0) * 100 / 255 }) {
                vehicleData.fuelLevel = fuel
                received = true
            }
        case 0x42:
            if bytes.count >= 2 {
                vehicleData.batteryVoltage = Double(Int(bytes[0]) * 256 + Int(bytes[1])) / 1000
                received = true
            }
        default:
            break
        }
        if received {
            // ⭐ تعديل: لو وصلت قراءة، نعتبرها مدعومة (عشان شاشة "تم الاتصال" ما تقول "غير متاح")
            supportedPIDs.insert(pid)
            vehicleData.lastRecordedAt = Date()
            vehicleData.save()
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
