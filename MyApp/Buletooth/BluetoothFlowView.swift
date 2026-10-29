import SwiftUI
import CoreBluetooth
#if canImport(UIKit)
import UIKit
#endif

struct BluetoothFlowView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var obdService: OBDService
    let carName: String
    let isDemoMode: Bool
    var onCancel: () -> Void = {}
    var onConnected: () -> Void = {}

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var screen = Screen.setup
    @State private var demoTask: Task<Void, Never>?
    private enum Screen { case setup, permission, devices, connection, success }
    private var isDemo: Bool { isDemoMode }
    private let demoDeviceID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 0)
                    if isDemo {
                        Text("وضع تجربة الواجهات — لا اتصال ولا قراءات حقيقية")
                            .font(.caption).foregroundStyle(.white)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }
                    content
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .background(Color.black.opacity(0.22).ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .onAppear {
            if !isDemo, obdService.state == .ready, bluetoothManager.state == .connected {
                screen = .success
            } else if !isDemo, SavedVehicle.load()?.brand == carName {
                screen = .devices
                bluetoothManager.start()
            }
        }
        .onChange(of: bluetoothManager.state) { _, state in
            guard !isDemo, screen == .connection, state == .connected else { return }
            obdService.startSession()
        }
        .onChange(of: obdService.state) { _, state in
            if !isDemo, screen == .connection, state == .ready { screen = .success }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, !isDemo, screen == .devices else { return }
            if bluetoothManager.state == .permissionDenied || bluetoothManager.state == .bluetoothOff || bluetoothManager.state == .idle {
                beginSearch()
            }
        }
        .onDisappear { demoTask?.cancel() }
    }

    // MARK: - Screen Router

    @ViewBuilder
    private var content: some View {
        if !isDemo, let message = failureMessage,
           screen == .devices || screen == .connection || screen == .success {
            BluetoothPopupView(
                state: .failed(message: message),
                onDeny: cancelFlow,
                onRetry: retry,
                failureTitle: bluetoothManager.state == .permissionDenied ? "الوصول إلى البلوتوث متوقف" : "تعذر إكمال الاتصال",
                retryTitle: bluetoothManager.state == .permissionDenied ? "فتح الإعدادات" : "إعادة المحاولة",
                showsBackdrop: false,
                failureSteps: recoverySteps,
                showsRetryIcon: bluetoothManager.state != .permissionDenied
            )
        } else {
            switch screen {
            case .setup: setup
            case .permission:
                BluetoothPopupView(state: .permission, onAllow: beginSearch,
                                   onDeny: cancelFlow, showsBackdrop: false)
            case .devices: devicePicker
            case .connection:
                BluetoothPopupView(
                    state: .connecting,
                    onDeny: cancelFlow,
                    progressTitle: progressTitle,
                    progressMessage: "ابقَ بالقرب من الجهاز. قد يستغرق التحقق من السيارة بعض الوقت.",
                    showsBackdrop: false
                )
            case .success: success
            }
        }
    }

    // MARK: - Prepare the Adapter

    private var setup: some View {
        card {
            VStack(spacing: 20) {
                adapterIllustration
                Text("جهّز جهاز قراءة السيارة")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("تحتاج جهاز LELink لقراءة بيانات سيارتك. بلوتوث السيارة وحده لا يكفي.")
                    .font(.system(size: 17)).foregroundStyle(CarVisualStyle.secondaryText)
                    .multilineTextAlignment(.center)
                ConnectionSteps(steps: [
                    "أوقف السيارة وأطفئ الإشعال، ثم ركّب الجهاز حسب تعليماته في منفذ OBD-II، غالبًا أسفل المقود.",
                    "شغّل إشعال السيارة والبلوتوث في هاتفك.",
                    "ابقَ بالقرب من السيارة واختر جهازك في الخطوة التالية."
                ])
                Button("البحث عن الجهاز", action: requestSearch)
                    .buttonStyle(PrimaryPopupButtonStyle())
                Text("لا تملك الجهاز؟ ستحتاج إليه لعرض قراءات سيارتك.")
                    .font(.system(size: 15)).foregroundStyle(CarVisualStyle.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func requestSearch() {
        if isDemo || CBManager.authorization == .notDetermined {
            screen = .permission
        } else {
            beginSearch()
        }
    }

    // MARK: - Explicit Device Selection

    private var devicePicker: some View {
        card {
            VStack(spacing: 20) {
                Text("اختر جهاز قراءة السيارة")
                    .font(.title3.bold()).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("اختر جهاز LELink المركّب في سيارتك.")
                    .font(.subheadline).foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                if isDemo {
                    deviceRow(OBDDevice(id: demoDeviceID, name: "LELink — جهاز تجريبي", signalStrength: -50))
                } else {
                    if bluetoothManager.state == .scanning || bluetoothManager.state == .waitingForPermission {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("جارٍ البحث عن الأجهزة القريبة…").font(.subheadline)
                        }.foregroundStyle(Color.white.opacity(0.68))
                    }
                    ForEach(bluetoothManager.devices) { device in deviceRow(device) }
                    if bluetoothManager.state == .scanFinished, bluetoothManager.devices.isEmpty {
                        Text("لم نعثر على جهاز. تأكد من تركيبه وتشغيل إشعال السيارة، وأغلق أي تطبيق آخر متصل به.")
                            .font(.subheadline).foregroundStyle(Color.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    if bluetoothManager.state == .scanFinished {
                        Button("إعادة البحث", action: beginSearch)
                            .buttonStyle(PrimaryPopupButtonStyle())
                    }
                }
            }
        }
    }

    private func deviceRow(_ device: OBDDevice) -> some View {
        Button {
            screen = .connection
            if isDemo {
                demoTask?.cancel()
                demoTask = Task {
                    do { try await Task.sleep(for: .seconds(2)) } catch { return }
                    guard !Task.isCancelled else { return }
                    screen = .success
                }
            } else {
                obdService.stopSession()
                bluetoothManager.connect(deviceID: device.id)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                VStack(alignment: .leading, spacing: 6) {
                    Text(device.name).font(.headline)
                    Text("معرّف: \(device.shortID)").font(.caption)
                        .foregroundStyle(Color.white.opacity(0.55))
                    if !isDemo, let saved = SavedVehicle.load(), saved.brand == carName,
                       saved.deviceID == device.id {
                        Text("الجهاز المحفوظ لهذه السيارة").font(.caption)
                            .foregroundStyle(Color.white.opacity(0.68))
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
            }
            .foregroundStyle(.white).padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.14)))
        }.buttonStyle(.plain)
    }

    // MARK: - Verified Connection and Partial Availability

    private var success: some View {
        BluetoothPopupView(
            state: .connected(carName: carName),
            onContinue: complete,
            onChangeDevice: beginSearch,
            successTitle: isDemo ? "معاينة نجاح الاتصال" : "تم الاتصال بنجاح",
            successMessage: isDemo ? "معاينة فقط؛ لا توجد قراءات حقيقية." : "",
            deviceName: isDemo ? "LELink — جهاز تجريبي" : bluetoothManager.connectedDeviceName ?? "LELink",
            readingDetails: isDemo ? [] : readingDetails,
            showsBackdrop: false
        )
        .task {
            // Cancelled automatically if the success view disappears or connection fails.
            do { try await Task.sleep(for: .seconds(1.5)) } catch { return }
            guard !Task.isCancelled else { return }
            complete()
        }
    }

    private var readingDetails: [String] {
        [
            reading("حرارة سائل التبريد", pid: 0x05, value: obdService.vehicleData.coolantTemperature, unit: "°C"),
            reading("مستوى الوقود", pid: 0x2F, value: obdService.vehicleData.fuelLevel, unit: "%"),
            reading("جهد وحدة التحكم", pid: 0x42, value: obdService.vehicleData.batteryVoltage, unit: "V")
        ]
    }

    private func reading(_ title: String, pid: UInt8, value: Double?, unit: String) -> String {
        guard obdService.supportedPIDs.contains(pid) else { return "\(title): غير متاح لهذه السيارة" }
        guard let value, let date = obdService.updatedAt[pid] else { return "\(title): لم تصل قراءة" }
        let label = Date().timeIntervalSince(date) <= 15 ? "" : " — آخر قراءة"
        return "\(title): \(String(format: "%.1f", value)) \(unit)\(label)"
    }

    private var progressTitle: String {
        if isDemo { return "محاكاة الاتصال…" }
        switch obdService.state {
        case .initializing: return "تم الاتصال بالجهاز، جارٍ تجهيزه…"
        case .checkingVehicle: return "نتحقق من بيانات السيارة…"
        default: return "يتم الاتصال بالجهاز…"
        }
    }

    private var failureMessage: String? {
        if case .failed(let message) = obdService.state { return message }
        switch bluetoothManager.state {
        case .failed(let message): return message
        case .bluetoothOff: return "البلوتوث مغلق. شغّله من إعدادات هاتفك، ثم أعد البحث."
        case .permissionDenied: return "لم يُسمح للتطبيق باستخدام البلوتوث. افتح الإعدادات واسمح بالوصول، ثم ارجع وأعد البحث."
        case .idle where screen == .success || screen == .connection: return "انتهت جلسة الاتصال. أعد البحث واختيار الجهاز لقراءة بيانات جديدة."
        default: return nil
        }
    }

    // MARK: - Actions and Shared Design

    private func beginSearch() {
        screen = .devices
        guard !isDemo else { return }
        obdService.stopSession()
        bluetoothManager.start()
    }

    private func retry() {
        if bluetoothManager.state == .permissionDenied {
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            #endif
        } else { beginSearch() }
    }

    private func cancelFlow() {
        demoTask?.cancel()
        obdService.stopSession()
        bluetoothManager.disconnect()
        onCancel()
    }

    private func complete() {
        if isDemo { cancelFlow(); return }
        guard obdService.state == .ready, bluetoothManager.state == .connected,
              let id = bluetoothManager.connectedDeviceID else { return }
        SavedVehicle(brand: carName, deviceID: id,
                     deviceName: bluetoothManager.connectedDeviceName ?? "LELink").save()
        onConnected()
    }

    // Code-drawn connector illustration: no new image assets or project references needed.
    private var adapterIllustration: some View {
        VStack(spacing: 0) {
            VStack(spacing: 5) {
                ForEach(0..<2) { _ in
                    HStack(spacing: 6) {
                        ForEach(0..<8) { _ in
                            Capsule().fill(Color.white.opacity(0.55)).frame(width: 5, height: 7)
                        }
                    }
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
            VStack(spacing: 4) {
                Text("LELink").font(.headline)
                Text("OBD-II").font(.caption2).foregroundStyle(Color.white.opacity(0.55))
            }
            .foregroundStyle(.white).frame(width: 112, height: 55)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.28)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.14)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("رسم توضيحي لمحوّل LELink بموصل فحص ذي ستة عشر سنًا")
    }

    private var recoverySteps: [String] {
        switch bluetoothManager.state {
        case .permissionDenied:
            return ["افتح الإعدادات واسمح للتطبيق باستخدام البلوتوث.", "ارجع إلى التطبيق للبحث عن الجهاز."]
        case .bluetoothOff:
            return ["شغّل البلوتوث من إعدادات هاتفك.", "ارجع إلى التطبيق وأعد المحاولة."]
        case .failed(let message) where message.contains("لا يدعم"):
            // An unsupported runtime is not fixed by installing the adapter.
            return []
        default:
            return ["تأكد من تركيب جهاز LELink وتشغيل إشعال السيارة.",
                    "ابقَ بالقرب من السيارة.", "أغلق أي تطبيق آخر متصل بالجهاز."]
        }
    }

    private func card<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View  {
        ConnectionCard(onClose: cancelFlow, content: content).padding(.horizontal, 24)
    }
}

#Preview("LELink Setup — Arabic") {
    let manager = BluetoothManager()
    BluetoothFlowView(bluetoothManager: manager, obdService: OBDService(bluetoothManager: manager),
                      carName: "تويوتا", isDemoMode: false)
}
