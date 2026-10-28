import Foundation

// MARK: - Bluetooth Connection State

enum BluetoothConnectionState: Equatable {
    case idle
    case waitingForPermission
    case bluetoothOff
    case scanning
    case connecting
    case connected
    case failed(String)
}


// MARK: - OBD Session State

enum OBDSessionState: Equatable {
    case idle
    case initializing
    case ready
    case failed(String)
}


// MARK: - Vehicle Data

struct VehicleData {

    var coolantTemperature: Double?
    var fuelLevel: Double?
    var batteryVoltage: Double?
    var rpm: Double?
}
