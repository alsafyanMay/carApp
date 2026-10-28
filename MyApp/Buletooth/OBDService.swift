import Foundation
import Combine

final class OBDService: ObservableObject {

    // MARK: - Published Data

    @Published private(set) var state: OBDSessionState = .idle
    @Published private(set) var vehicleData = VehicleData()


    // MARK: - Dependencies

    private let bluetoothManager: BluetoothManager


    // MARK: - Command Handling

    private var responseBuffer = ""

    private var currentCommand: String?
    private var commandQueue: [String] = []

    private var pollingTimer: Timer?
    private var isInitializing = false


    // MARK: - Initialization

    init(bluetoothManager: BluetoothManager) {

        self.bluetoothManager = bluetoothManager

        bluetoothManager.onTextReceived = { [weak self] text in
            self?.receive(text)
        }
    }


    // MARK: - Start OBD Session

    func startSession() {

        guard bluetoothManager.state == .connected else {
            return
        }

        stopPolling()

        responseBuffer = ""
        currentCommand = nil

        state = .initializing
        isInitializing = true

        // Basic ELM/STN initialization sequence.
        commandQueue = [
            "ATZ",     // Reset adapter
            "ATE0",    // Disable command echo
            "ATL0",    // Disable line feeds
            "ATS0",    // Disable spaces
            "ATH0",    // Disable headers
            "ATSP0"    // Automatically select vehicle protocol
        ]

        sendNextCommand()
    }


    // MARK: - Poll Vehicle Data

    private func requestVehicleData() {

        guard
            state == .ready,
            currentCommand == nil
        else {
            return
        }

        // Standard OBD-II Mode 01 requests.
        commandQueue = [
            "0105",    // Engine coolant temperature
            "012F",    // Fuel level
            "0142",    // Control module voltage
            "010C"     // Engine RPM
        ]

        sendNextCommand()
    }


    // MARK: - Command Queue

    private func sendNextCommand() {

        guard currentCommand == nil else {
            return
        }

        guard !commandQueue.isEmpty else {

            if isInitializing {

                isInitializing = false
                state = .ready

                startPolling()
            }

            return
        }

        let command = commandQueue.removeFirst()

        currentCommand = command

        bluetoothManager.send(
            command: command
        )
    }


    // MARK: - Receive Adapter Data

    private func receive(_ text: String) {

        responseBuffer += text

        // OBD adapters use ">" as the prompt that indicates
        // the response has finished and the adapter is ready.
        while let promptIndex = responseBuffer.firstIndex(of: ">") {

            let response = String(
                responseBuffer[..<promptIndex]
            )

            responseBuffer.removeSubrange(
                ...promptIndex
            )

            processResponse(response)
        }
    }


    // MARK: - Process Response

    private func processResponse(_ response: String) {

        guard let command = currentCommand else {
            return
        }

        currentCommand = nil

        if response.uppercased().contains("NO DATA") {

            // A PID can be part of the OBD-II standard
            // without being supported by every vehicle.
            sendNextCommand()
            return
        }

        if response.uppercased().contains("ERROR") {

            state = .failed(
                "The OBD adapter returned an error."
            )

            return
        }

        parse(
            command: command,
            response: response
        )

        sendNextCommand()
    }


    // MARK: - OBD Parser

    private func parse(
        command: String,
        response: String
    ) {

        let hex = normalizedHex(
            from: response
        )

        switch command {

        case "0105":
            parseCoolantTemperature(hex)

        case "012F":
            parseFuelLevel(hex)

        case "0142":
            parseBatteryVoltage(hex)

        case "010C":
            parseRPM(hex)

        default:
            // AT initialization commands do not contain vehicle values.
            break
        }
    }


    // MARK: - Coolant Temperature

    private func parseCoolantTemperature(
        _ hex: String
    ) {

        guard
            let value = byte(
                after: "4105",
                in: hex
            )
        else {
            return
        }

        // Formula: A - 40
        vehicleData.coolantTemperature =
            Double(value - 40)
    }


    // MARK: - Fuel Level

    private func parseFuelLevel(
        _ hex: String
    ) {

        guard
            let value = byte(
                after: "412F",
                in: hex
            )
        else {
            return
        }

        // Formula: A × 100 / 255
        vehicleData.fuelLevel =
            Double(value) * 100.0 / 255.0
    }


    // MARK: - Battery / Control Module Voltage

    private func parseBatteryVoltage(
        _ hex: String
    ) {

        guard
            let values = twoBytes(
                after: "4142",
                in: hex
            )
        else {
            return
        }

        let rawValue =
            values.0 * 256 + values.1

        // Formula: (256A + B) / 1000
        vehicleData.batteryVoltage =
            Double(rawValue) / 1000.0
    }


    // MARK: - RPM

    private func parseRPM(
        _ hex: String
    ) {

        guard
            let values = twoBytes(
                after: "410C",
                in: hex
            )
        else {
            return
        }

        let rawValue =
            values.0 * 256 + values.1

        // Formula: (256A + B) / 4
        vehicleData.rpm =
            Double(rawValue) / 4.0
    }


    // MARK: - Response Helpers

    private func normalizedHex(
        from response: String
    ) -> String {

        response
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }


    private func byte(
        after marker: String,
        in text: String
    ) -> Int? {

        guard let range = text.range(of: marker) else {
            return nil
        }

        let start = range.upperBound

        guard
            text.distance(
                from: start,
                to: text.endIndex
            ) >= 2
        else {
            return nil
        }

        let end = text.index(
            start,
            offsetBy: 2
        )

        return Int(
            text[start..<end],
            radix: 16
        )
    }


    private func twoBytes(
        after marker: String,
        in text: String
    ) -> (Int, Int)? {

        guard let range = text.range(of: marker) else {
            return nil
        }

        let start = range.upperBound

        guard
            text.distance(
                from: start,
                to: text.endIndex
            ) >= 4
        else {
            return nil
        }

        let middle = text.index(
            start,
            offsetBy: 2
        )

        let end = text.index(
            start,
            offsetBy: 4
        )

        guard
            let first = Int(
                text[start..<middle],
                radix: 16
            ),
            let second = Int(
                text[middle..<end],
                radix: 16
            )
        else {
            return nil
        }

        return (
            first,
            second
        )
    }


    // MARK: - Polling

    private func startPolling() {

        stopPolling()

        // Read the vehicle values immediately.
        requestVehicleData()

        // Refresh values periodically while connected.
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: 3,
            repeats: true
        ) { [weak self] _ in

            self?.requestVehicleData()
        }
    }


    private func stopPolling() {

        pollingTimer?.invalidate()
        pollingTimer = nil
    }


    // MARK: - Stop Session

    func stopSession() {

        stopPolling()

        commandQueue.removeAll()
        currentCommand = nil
        responseBuffer = ""

        state = .idle
    }
}
