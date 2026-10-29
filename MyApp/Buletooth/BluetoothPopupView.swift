import SwiftUI

enum CarVisualStyle {
    // Approximation sampled from the supplied Sketch screenshot, not a Sketch token export.
    static let popup = Color(red: 28/255, green: 34/255, blue: 33/255)
    static let secondaryText = Color(red: 173/255, green: 190/255, blue: 180/255)
    static let background = LinearGradient(stops: [
        .init(color: Color(red: 0.14, green: 0.17, blue: 0.14), location: 0),
        .init(color: Color(red: 0.17, green: 0.22, blue: 0.18), location: 0.45),
        .init(color: Color(red: 0.10, green: 0.12, blue: 0.11), location: 1)
    ], startPoint: .top, endPoint: .bottom)
}

struct ConnectionCard<Content: View>: View {
    var onClose: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 16) {
            if let onClose {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CarVisualStyle.secondaryText)
                            .frame(width: 44, height: 44)
                    }.accessibilityLabel("إغلاق")
                    Spacer()
                }.padding(.top, -12).padding(.leading, -12)
            }
            content()
        }
        .padding(24)
        .frame(maxWidth: 390)
        .background(RoundedRectangle(cornerRadius: 32).fill(CarVisualStyle.popup))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.14)))
        .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
    }
}

struct ConnectionSteps: View {
    let steps: [String]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                if index > 0 { Divider().overlay(Color.white.opacity(0.12)) }
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 17))
                .foregroundStyle(CarVisualStyle.secondaryText)
                .padding(16)
            }
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.045)))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

enum BluetoothPopupState {
    case permission, connecting
    case connected(carName: String)
    case failed(message: String)
}

struct BluetoothPopupView: View {
    let state: BluetoothPopupState
    var onAllow: () -> Void = {}
    var onDeny: () -> Void = {}
    var onRetry: () -> Void = {}
    var onContinue: () -> Void = {} // Completion is owned by the flow, no success button.
    var onChangeDevice: (() -> Void)? = nil
    var progressTitle = "جارٍ الاتصال بالجهاز…"
    var progressMessage = "ابقَ بالقرب من السيارة."
    var successTitle = "تم الاتصال بنجاح"
    var successMessage = ""
    var deviceName = ""
    var readingDetails: [String] = []
    var failureTitle = "تعذر الاتصال بالسيارة"
    var retryTitle = "إعادة المحاولة"
    var showsBackdrop = true
    var failureSteps = ["تأكد من تركيب جهاز LELink وتشغيل إشعال السيارة.",
                        "ابقَ بالقرب من السيارة.", "أغلق أي تطبيق آخر متصل بالجهاز."]
    var showsRetryIcon = true

    var body: some View {
        ZStack {
            if showsBackdrop { Color.black.opacity(0.22).ignoresSafeArea() }
            ConnectionCard(onClose: allowsClose ? onDeny : nil) {
                VStack(spacing: 20) { content }
            }
            .padding(.horizontal, 24)
        }
        // The same component and direction in runtime and every preview.
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .preferredColorScheme(.dark)
    }

    private var allowsClose: Bool {
        if case .failed = state { return true }
        if case .connecting = state { return true }
        return false
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .permission:
            bluetoothIcon
            title("الاتصال بجهاز القراءة")
            message("نحتاج إلى البلوتوث للعثور على جهاز LELink في سيارتك. سيطلب iPhone إذنك في الخطوة التالية.")
            Button("متابعة", action: onAllow).buttonStyle(PrimaryPopupButtonStyle())
        case .connecting:
            ProgressView().controlSize(.large).tint(CarVisualStyle.secondaryText)
            title(progressTitle)
            message(progressMessage)
        case .connected(let carName):
            connectionIcon(color: Color(red: 0.60, green: 0.75, blue: 0.64))
            title(successTitle)
            HStack(spacing: 10) {
                Circle().fill(Color(red: 0.60, green: 0.75, blue: 0.64)).frame(width: 12, height: 12)
                Text(carName)
            }
            .foregroundStyle(.white).padding(.horizontal, 18).padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            if !successMessage.isEmpty { message(successMessage) }
        case .failed(let text):
            connectionIcon(color: Color(red: 0.87, green: 0.57, blue: 0.54))
            title(failureTitle)
            if !text.isEmpty { message(text) }
            if !failureSteps.isEmpty { ConnectionSteps(steps: failureSteps) }
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    if showsRetryIcon { Image(systemName: "arrow.clockwise") }
                    Text(retryTitle)
                }.frame(maxWidth: .infinity)
            }.buttonStyle(PrimaryPopupButtonStyle())
        }
    }

    private func title(_ text: String) -> some View {
        Text(text).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    private func message(_ text: String) -> some View {
        Text(text).font(.system(size: 17)).foregroundStyle(CarVisualStyle.secondaryText)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }
    private var bluetoothIcon: some View {
        Image(systemName: "antenna.radiowaves.left.and.right")
            .font(.system(size: 20)).foregroundStyle(CarVisualStyle.secondaryText)
            .frame(width: 50, height: 50)
            .background(Circle().fill(Color.white.opacity(0.07)))
            .overlay(Circle().stroke(Color.white.opacity(0.2)))
            .accessibilityHidden(true)
    }
    private func connectionIcon(color: Color) -> some View {
        HStack(spacing: 12) {
            bluetoothIcon
            HStack(spacing: 5) { ForEach(0..<3) { _ in Circle().fill(color).frame(width: 5, height: 5) } }
            Image(systemName: "car.side").font(.system(size: 20)).foregroundStyle(color)
                .frame(width: 42, height: 42).overlay(Circle().stroke(color))
        }.accessibilityHidden(true)
    }
}

struct PrimaryPopupButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 20, weight: .medium)).foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 12).padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.75 : 1)))
    }
}
struct SecondaryPopupButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 17)).foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.07)))
            .overlay(Capsule().stroke(Color.white.opacity(0.20)))
    }
}

#Preview("Permission — Arabic") { BluetoothPopupView(state: .permission) }
#Preview("Connecting — Arabic") { BluetoothPopupView(state: .connecting) }
#Preview("Connected — Arabic") { BluetoothPopupView(state: .connected(carName: "تويوتا")) }
#Preview("Failed — Arabic") { BluetoothPopupView(state: .failed(message: "لم نتلقَّ ردًا من السيارة.")) }
