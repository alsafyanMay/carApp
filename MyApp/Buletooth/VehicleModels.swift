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

struct VehicleData: Codable {
    var coolantTemperature: Double?
    var fuelLevel: Double?
    // PID 42 reports control-module voltage, not battery health or charge percentage.
    var batteryVoltage: Double?
    var rpm: Double?
    var lastRecordedAt: Date?

    private static let key = "lastKnownVehicleData.v1"

    static func load() -> VehicleData? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(VehicleData.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
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

// MARK: - 🆕 التحقق من شركة السيارة عن طريق رقم الهيكل (VIN)

// نتيجة المقارنة بين الشركة اللي اختارها المستخدم والشركة اللي في الـ VIN
enum VehicleBrandCheck: Equatable {
    // الـ VIN يطابق الشركة المختارة
    case match
    // الـ VIN لشركة ثانية (detected = اسمها لو نعرفه)
    case mismatch(detected: String?)
    // ما قدرنا نتأكد: السيارة ما أعطت VIN، أو رمزه مو في قائمتنا، أو المستخدم اختار "شركة أخرى"
    case unknown
}

enum VehicleBrandCatalog {
    // أول حروف رقم الهيكل (WMI) لكل شركة.
    // ⚠️ قائمة بالرموز الشائعة وليست كاملة: الشركة الوحدة تصنّع في أكثر من دولة،
    // فجرّبوها على سياراتكم وأضيفوا أي رمز ناقص هنا.
    static let prefixes: [String: [String]] = [
        "تويوتا": ["JT", "4T", "5T", "2T", "MR0", "MHF", "AHT", "NMT", "SB1", "6T1", "8AJ", "9BR", "LTV", "LVG"],
        "شانجان": ["LS4", "LS5", "LS6"],
        "هافال": ["LGW"]
    ]

    // نعرف الشركة من الـ VIN (nil لو الرمز مو في القائمة)
    static func brand(forVIN vin: String) -> String? {
        let upper = vin.uppercased()
        return prefixes.first { _, codes in codes.contains { upper.hasPrefix($0) } }?.key
    }

    // نقارن الـ VIN بالشركة اللي اختارها المستخدم
    static func check(vin: String?, selectedBrand: String) -> VehicleBrandCheck {
        // "شركة أخرى" أو شركة ما عندنا رموزها → ما نتحقق
        guard let expected = prefixes[selectedBrand] else { return .unknown }
        // السيارة ما أعطت VIN
        guard let vin, vin.count == 17 else { return .unknown }
        let upper = vin.uppercased()
        // يطابق؟
        if expected.contains(where: { upper.hasPrefix($0) }) { return .match }
        // لشركة ثانية نعرفها؟ → عدم تطابق أكيد
        if let other = brand(forVIN: upper) { return .mismatch(detected: other) }
        // رمز ما نعرفه → ما نقدر نجزم إنه غلط
        return .unknown
    }
}
