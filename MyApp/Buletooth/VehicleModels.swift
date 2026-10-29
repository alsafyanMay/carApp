import Foundation

// MARK: - Connection States

enum BluetoothConnectionState: Equatable {
    case idle, waitingForPermission, bluetoothOff, permissionDenied
    case scanning, scanFinished, connecting, connected
    case failed(String)
}

enum OBDSessionState: Equatable {
    case idle, initializing, checkingVehicle, ready
    case failed(String)
}

struct OBDDevice: Identifiable {
    let id: UUID
    let name: String
    let signalStrength: Int

    // Device names are not unique; this suffix helps distinguish nearby adapters.
    var shortID: String { String(id.uuidString.suffix(6)) }
}

// MARK: - Live Vehicle Data

struct VehicleData {
    var coolantTemperature: Double?
    var fuelLevel: Double?
    // PID 42 reports control-module voltage, not battery health or charge percentage.
    var batteryVoltage: Double?
    var rpm: Double?
}

// MARK: - Local Vehicle Profile

struct SavedVehicle: Codable {
    let brand: String
    let deviceID: UUID
    let deviceName: String

    private static let key = "savedOBDVehicle.v1"

    static func load() -> SavedVehicle? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SavedVehicle.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
