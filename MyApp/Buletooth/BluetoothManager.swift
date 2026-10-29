import Foundation
import CoreBluetooth
import Combine

@MainActor
final class BluetoothManager: NSObject, ObservableObject {
    @Published private(set) var state: BluetoothConnectionState = .idle
    @Published private(set) var devices: [OBDDevice] = []
    @Published private(set) var connectedDeviceName: String?
    @Published private(set) var connectedDeviceID: UUID?

    var onTextReceived: ((String) -> Void)?
    var onConnectionLost: (() -> Void)?

    private var centralManager: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var peripheral: CBPeripheral?
    private var channel: CBCharacteristic?
    private var timeoutTask: Task<Void, Never>?
    private var wantsScan = false

    // LELink: one serial service and one shared write/notify characteristic.
    // Reference: https://tech.aptpod.co.jp/entry/2021/12/10/070000
    // Verify these on the team's physical adapter before claiming hardware support.
    private let serviceUUID = CBUUID(string: "FFE0")
    private let channelUUID = CBUUID(string: "FFE1")

    // MARK: - Discovery and User Selection

    func start() {
        disconnect()
        devices = []
        peripherals = [:]
        wantsScan = true
        if let centralManager {
            handleState(centralManager.state)
        } else {
            state = .waitingForPermission
            centralManager = CBCentralManager(delegate: self, queue: .main)
        }
    }

    func retry() { start() }

    private func scan() {
        guard let centralManager, centralManager.state == .poweredOn else { return }
        state = .scanning
        // The service is shared by other BLE products; a name/service match alone
        // does not prove that a device is an OBD adapter. OBDService verifies it.
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        setTimeout(seconds: 12) { manager in
            manager.centralManager?.stopScan()
            manager.wantsScan = false
            manager.state = .scanFinished
        }
    }

    func connect(deviceID: UUID) {
        guard let target = peripherals[deviceID] else {
            fail("لم يعد الجهاز متاحًا. ابحث عنه مرة أخرى.")
            return
        }
        timeoutTask?.cancel()
        wantsScan = false
        centralManager?.stopScan()
        peripheral = target
        target.delegate = self
        state = .connecting
        centralManager?.connect(target, options: nil)
        setTimeout(seconds: 20) { manager in
            manager.fail("انتهت مهلة الاتصال بالجهاز. تأكد أنه قريب وغير مستخدم في تطبيق آخر.")
        }
    }

    // MARK: - Read-only OBD Transport

    @discardableResult
    func send(command: String) -> Bool {
        guard state == .connected, let peripheral, let channel,
              let data = (command + "\r").data(using: .utf8) else { return false }
        // Commands are short and serialized by OBDService.
        let type: CBCharacteristicWriteType = channel.properties.contains(.write)
            ? .withResponse : .withoutResponse
        guard data.count <= peripheral.maximumWriteValueLength(for: type) else { return false }
        if type == .withoutResponse && !peripheral.canSendWriteWithoutResponse { return false }
        peripheral.writeValue(data, for: channel, type: type)
        return true
    }

    func disconnect() {
        wantsScan = false
        timeoutTask?.cancel()
        centralManager?.stopScan()
        let previous = peripheral
        peripheral = nil
        channel = nil
        connectedDeviceID = nil
        connectedDeviceName = nil
        if let previous { centralManager?.cancelPeripheralConnection(previous) }
        onConnectionLost?()
        state = .idle
    }

    private func fail(_ message: String) {
        disconnect()
        state = .failed(message)
    }

    private func setTimeout(seconds: Double, action: @escaping (BluetoothManager) -> Void) {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard !Task.isCancelled, let self else { return }
            action(self)
        }
    }

    private func handleState(_ bluetoothState: CBManagerState) {
        switch bluetoothState {
        case .poweredOn:
            if wantsScan { scan() }
        case .poweredOff:
            disconnect()
            state = .bluetoothOff
        case .unauthorized:
            disconnect()
            state = .permissionDenied
        case .unsupported:
            fail("هذا الجهاز لا يدعم اتصال البلوتوث المطلوب.")
        case .resetting:
            fail("البلوتوث يعيد التشغيل. حاول مرة أخرى بعد قليل.")
        case .unknown:
            state = .waitingForPermission
        @unknown default:
            fail("تعذر تشغيل البلوتوث. حاول مرة أخرى.")
        }
    }
}

// CoreBluetooth callbacks use the main queue configured above.
extension BluetoothManager: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleState(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard state == .scanning else { return }
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? "جهاز BLE بدون اسم"
        peripherals[peripheral.identifier] = peripheral
        let device = OBDDevice(id: peripheral.identifier, name: name, signalStrength: RSSI.intValue)
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        // Never connect to the first result automatically. The user selects it.
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard self.peripheral === peripheral else { return }
        connectedDeviceName = peripheral.name ?? devices.first(where: { $0.id == peripheral.identifier })?.name
        connectedDeviceID = peripheral.identifier
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        guard self.peripheral === peripheral else { return }
        fail("تعذر الاتصال بالجهاز. تأكد من تركيبه وإغلاق أي تطبيق آخر متصل به.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard self.peripheral === peripheral else { return }
        fail("انقطع الاتصال بجهاز القراءة. تأكد من تركيبه والبقاء بالقرب منه.")
    }
}

extension BluetoothManager: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard self.peripheral === peripheral else { return }
        guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            fail("الجهاز المختار لا يوفر قناة الاتصال المطلوبة لـ LELink.")
            return
        }
        peripheral.discoverCharacteristics([channelUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard self.peripheral === peripheral else { return }
        guard error == nil,
              let channel = service.characteristics?.first(where: { $0.uuid == channelUUID }),
              channel.properties.contains(.notify) || channel.properties.contains(.indicate),
              channel.properties.contains(.write) || channel.properties.contains(.writeWithoutResponse) else {
            fail("لا يمكن إرسال الأوامر واستقبال البيانات من هذا الجهاز.")
            return
        }
        self.channel = channel
        peripheral.setNotifyValue(true, for: channel)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard self.peripheral === peripheral, characteristic.uuid == channelUUID else { return }
        guard error == nil, characteristic.isNotifying else {
            fail("تعذر استقبال البيانات من الجهاز. إذا طلب النظام رمز اقتران، استخدم رمز جهازك.")
            return
        }
        timeoutTask?.cancel()
        state = .connected // Transport only; this does not confirm vehicle access.
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard self.peripheral === peripheral, characteristic.uuid == channelUUID else { return }
        guard error == nil else {
            fail("تعذر استقبال رد الجهاز. حاول إعادة الاتصال.")
            return
        }
        guard let data = characteristic.value, let text = String(data: data, encoding: .ascii) else { return }
        onTextReceived?(text)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard self.peripheral === peripheral, characteristic.uuid == channelUUID, error != nil else { return }
        fail("تعذر إرسال الطلب للجهاز. تحقق من رمز الاقتران إن كان جهازك محميًا.")
    }
}
