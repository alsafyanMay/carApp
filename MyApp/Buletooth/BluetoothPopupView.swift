import SwiftUI

enum BluetoothPopupState {
    case permission
    case connecting
    case connected(carName: String)
    case failed(message: String)
}

struct BluetoothPopupView: View {

    let state: BluetoothPopupState

    var onAllow: () -> Void = {}
    var onDeny: () -> Void = {}
    var onRetry: () -> Void = {}

    var body: some View {
        ZStack {

            // Dark overlay behind the popup.
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            popupContent
                .padding(.horizontal, 32)
        }
    }
}


// MARK: - Popup Router

private extension BluetoothPopupView {

    @ViewBuilder
    var popupContent: some View {

        switch state {

        case .permission:
            permissionPopup

        case .connecting:
            connectingPopup

        case .connected(let carName):
            connectedPopup(carName: carName)

        case .failed(let message):
            failedPopup(message: message)
        }
    }
}


// MARK: - Permission Popup

private extension BluetoothPopupView {

    var permissionPopup: some View {

        standardPopupContainer {

            VStack(spacing: 20) {

                bluetoothIcon

                VStack(spacing: 8) {

                    Text("اسمح بالوصول إلى البلوتوث")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(
                        "يحتاج التطبيق إلى البلوتوث للاتصال بجهاز السيارة وقراءة بياناتها."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        Color.white.opacity(0.68)
                    )
                    .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {

                    Button("رفض") {
                        onDeny()
                    }
                    .buttonStyle(
                        SecondaryPopupButtonStyle()
                    )

                    Button("سماح") {
                        onAllow()
                    }
                    .buttonStyle(
                        PrimaryPopupButtonStyle()
                    )
                }
            }
        }
    }
}


// MARK: - Connecting Popup

private extension BluetoothPopupView {

    var connectingPopup: some View {

        standardPopupContainer {

            VStack(spacing: 22) {

                ProgressView()
                    .controlSize(.large)
                    .tint(
                        Color.white.opacity(0.6)
                    )

                VStack(spacing: 8) {

                    Text("يتم الاتصال بالسيارة...")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(
                        "تأكد من تشغيل السيارة والبقاء بالقرب منها."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        Color.white.opacity(0.68)
                    )
                    .multilineTextAlignment(.center)
                }
            }
        }
    }
}


// MARK: - Connected Popup

private extension BluetoothPopupView {

    func connectedPopup(
        carName: String
    ) -> some View {

        standardPopupContainer {

            VStack(spacing: 20) {

                connectionStatusIcon(
                    color: .green
                )

                Text("تم الاتصال بنجاح")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                HStack(spacing: 10) {

                    Text(carName)
                        .foregroundStyle(.white)

                    Circle()
                        .fill(.green)
                        .frame(
                            width: 12,
                            height: 12
                        )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background {

                    Capsule()
                        .fill(
                            Color.white.opacity(0.08)
                        )
                }
            }
        }
    }
}


// MARK: - Failed Popup

private extension BluetoothPopupView {

    func failedPopup(
        message: String
    ) -> some View {

        failedPopupContainer {

            VStack(spacing: 20) {

                connectionStatusIcon(
                    color: .red
                )

                VStack(spacing: 8) {

                    Text("تعذر الاتصال بالسيارة")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(
                        "تأكد من تشغيل البلوتوث واتبع الخطوات التالية:"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        Color.white.opacity(0.68)
                    )
                    .multilineTextAlignment(.center)
                }

                troubleshootingSteps

                Button {
                    onRetry()
                } label: {

                    HStack(spacing: 8) {

                        Image(
                            systemName: "arrow.clockwise"
                        )

                        Text("إعادة المحاولة")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    PrimaryPopupButtonStyle()
                )

                if !message.isEmpty {

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(
                            Color.white.opacity(0.45)
                        )
                        .multilineTextAlignment(.center)
                }
            }
        }
    }


    var troubleshootingSteps: some View {

        VStack(spacing: 0) {

            troubleshootingRow(
                "1. شغّل البلوتوث على هاتفك."
            )

            Divider()
                .overlay(
                    Color.white.opacity(0.15)
                )

            troubleshootingRow(
                "2. شغّل السيارة."
            )

            Divider()
                .overlay(
                    Color.white.opacity(0.15)
                )

            troubleshootingRow(
                "3. ابقَ بالقرب من السيارة."
            )
        }
        .background {

            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(
                Color.white.opacity(0.05)
            )
        }
    }


    func troubleshootingRow(
        _ text: String
    ) -> some View {

        Text(text)
            .font(.subheadline)
            .foregroundStyle(
                Color.white.opacity(0.72)
            )
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
}


// MARK: - Shared Popup Containers

private extension BluetoothPopupView {

    // Used by Permission, Connecting, and Connected
    // so all three have the same visual size.
    func standardPopupContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {

        content()
            .padding(28)
            .frame(
                maxWidth: 379,
                minHeight: 253
            )
            .background {

                RoundedRectangle(
                    cornerRadius: 32
                )
                .fill(
                    Color(
                        red: 0.05,
                        green: 0.10,
                        blue: 0.09
                    )
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 32
                    )
                    .stroke(
                        Color.white.opacity(0.14)
                    )
                }
            }
    }


    // Failed popup is intentionally taller
    // because it contains troubleshooting details.
    func failedPopupContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {

        content()
            .padding(28)
            .frame(
                maxWidth: 390
            )
            .background {

                RoundedRectangle(
                    cornerRadius: 32
                )
                .fill(
                    Color(
                        red: 0.05,
                        green: 0.10,
                        blue: 0.09
                    )
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 32
                    )
                    .stroke(
                        Color.white.opacity(0.14)
                    )
                }
            }
    }
}


// MARK: - Shared Icons

private extension BluetoothPopupView {

    var bluetoothIcon: some View {

        Image(
            systemName:
                "antenna.radiowaves.left.and.right"
        )
        .font(
            .system(
                size: 20,
                weight: .medium
            )
        )
        .foregroundStyle(.white)
        .frame(
            width: 50,
            height: 50
        )
        .background {

            Circle()
                .fill(
                    Color.white.opacity(0.08)
                )
                .overlay {

                    Circle()
                        .stroke(
                            Color.white.opacity(0.22)
                        )
                }
        }
    }


    func connectionStatusIcon(
        color: Color
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName: "car.side"
            )
            .foregroundStyle(color)
            .frame(
                width: 40,
                height: 40
            )
            .background {

                Circle()
                    .stroke(
                        color.opacity(0.6)
                    )
            }

            HStack(spacing: 5) {

                ForEach(
                    0..<3,
                    id: \.self
                ) { _ in

                    Circle()
                        .fill(color)
                        .frame(
                            width: 6,
                            height: 6
                        )
                }
            }

            bluetoothIcon
        }
    }
}


// MARK: - Button Styles

private struct PrimaryPopupButtonStyle:
    ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {

                Capsule()
                    .fill(
                        Color.white.opacity(
                            configuration.isPressed
                            ? 0.75
                            : 1
                        )
                    )
            }
    }
}


private struct SecondaryPopupButtonStyle:
    ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {

                Capsule()
                    .fill(
                        Color.white.opacity(0.07)
                    )
                    .overlay {

                        Capsule()
                            .stroke(
                                Color.white.opacity(0.25)
                            )
                    }
            }
    }
}


// MARK: - Previews

#Preview("Permission") {

    BluetoothPopupView(
        state: .permission
    )
}


#Preview("Connecting") {

    BluetoothPopupView(
        state: .connecting
    )
}


#Preview("Connected") {

    BluetoothPopupView(
        state: .connected(
            carName: "MyCar22"
        )
    )
}


#Preview("Failed") {

    BluetoothPopupView(
        state: .failed(
            message: ""
        )
    )
}
