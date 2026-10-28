import Foundation
import CoreBluetooth
import Combine

final class BluetoothManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var state: BluetoothConnectionState = .idle
    @Published private(set) var connectedDeviceName: String?

    // Sends received Bluetooth text to OBDService
    var onTextReceived: ((String) -> Void)?


    // MARK: - Core Bluetooth

    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?

    private var notifyCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?


    // MARK: - OBDLink CX BLE UUIDs

    private let uartServiceUUID = CBUUID(string: "FFF0")
    private let notifyCharacteristicUUID = CBUUID(string: "FFF1")
    private let writeCharacteristicUUID = CBUUID(string: "FFF2")


    // MARK: - Start Bluetooth

    func start() {

        // Creating CBCentralManager triggers the iOS Bluetooth
        // permission request the first time the app uses Bluetooth.

        if centralManager == nil {

            state = .waitingForPermission

            centralManager = CBCentralManager(
                delegate: self,
                queue: .main
            )

        } else {

            handleBluetoothState()
        }
    }


    // MARK: - Retry Connection

    func retry() {

        disconnect()

        guard let centralManager else {
            start()
            return
        }

        if centralManager.state == .poweredOn {
            startScanning()
        } else {
            handleBluetoothState()
        }
    }


    // MARK: - Scan

    private func startScanning() {

        guard let centralManager else {
            return
        }

        state = .scanning

        centralManager.stopScan()

        // Search only for devices advertising the OBDLink CX UART service.
        centralManager.scanForPeripherals(
            withServices: [uartServiceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
    }


    // MARK: - Connect

    private func connect(to peripheral: CBPeripheral) {

        state = .connecting

        centralManager?.stopScan()

        self.peripheral = peripheral
        peripheral.delegate = self

        centralManager?.connect(
            peripheral,
            options: nil
        )
    }


    // MARK: - Send OBD Command

    func send(command: String) {

        guard
            state == .connected,
            let peripheral,
            let writeCharacteristic
        else {
            return
        }

        let commandWithReturn = command + "\r"

        guard let data = commandWithReturn.data(
            using: .utf8
        ) else {
            return
        }

        // OBDLink CX supports write and writeWithoutResponse.
        let writeType: CBCharacteristicWriteType =
            writeCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse

        peripheral.writeValue(
            data,
            for: writeCharacteristic,
            type: writeType
        )
    }


    // MARK: - Disconnect

    func disconnect() {

        centralManager?.stopScan()

        if let peripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }

        peripheral = nil
        notifyCharacteristic = nil
        writeCharacteristic = nil

        connectedDeviceName = nil

        state = .idle
    }


    // MARK: - Bluetooth State

    private func handleBluetoothState() {

        guard let centralManager else {
            return
        }

        switch centralManager.state {

        case .poweredOn:
            startScanning()

        case .poweredOff:
            state = .bluetoothOff

        case .unauthorized:
            state = .failed(
                "Bluetooth permission was denied."
            )

        case .unsupported:
            state = .failed(
                "Bluetooth is not supported on this device."
            )

        case .resetting:
            state = .idle

        case .unknown:
            state = .idle

        @unknown default:
            state = .failed(
                "Unknown Bluetooth state."
            )
        }
    }
}


// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {

        handleBluetoothState()
    }


    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {

        // The service filter already limits discovery
        // to the supported OBD adapter.

        connect(to: peripheral)
    }


    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {

        connectedDeviceName =
            peripheral.name ?? "OBDLink CX"

        peripheral.discoverServices(
            [uartServiceUUID]
        )
    }


    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {

        state = .failed(
            "Unable to connect to the OBD adapter."
        )
    }


    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {

        if state != .idle {
            state = .failed(
                "The OBD adapter was disconnected."
            )
        }
    }
}


// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {

        if error != nil {

            state = .failed(
                "Could not discover OBD services."
            )

            return
        }

        guard let services = peripheral.services else {
            return
        }

        for service in services {

            guard service.uuid == uartServiceUUID else {
                continue
            }

            peripheral.discoverCharacteristics(
                [
                    notifyCharacteristicUUID,
                    writeCharacteristicUUID
                ],
                for: service
            )
        }
    }


    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {

        if error != nil {

            state = .failed(
                "Could not discover OBD characteristics."
            )

            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {

            if characteristic.uuid == notifyCharacteristicUUID {

                notifyCharacteristic = characteristic

                // Subscribe so the adapter can send responses to the app.
                peripheral.setNotifyValue(
                    true,
                    for: characteristic
                )
            }

            if characteristic.uuid == writeCharacteristicUUID {
                writeCharacteristic = characteristic
            }
        }

        updateReadyStateIfPossible()
    }


    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        if error != nil {

            state = .failed(
                "Could not enable OBD notifications."
            )

            return
        }

        updateReadyStateIfPossible()
    }


    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        guard
            error == nil,
            characteristic.uuid == notifyCharacteristicUUID,
            let data = characteristic.value,
            let text = String(
                data: data,
                encoding: .utf8
            )
        else {
            return
        }

        onTextReceived?(text)
    }


    // MARK: - Ready Check

    private func updateReadyStateIfPossible() {

        guard
            let notifyCharacteristic,
            writeCharacteristic != nil,
            notifyCharacteristic.isNotifying
        else {
            return
        }

        state = .connected
    }
}
