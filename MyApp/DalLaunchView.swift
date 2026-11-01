import SwiftUI

// ألوان مقاربة لصور واجهات التطبيق.
private enum DalLaunchPalette {
    static let top = Color(
        red: 36 / 255.0,
        green: 51 / 255.0,
        blue: 41 / 255.0
    )

    static let bottom = Color(
        red: 24 / 255.0,
        green: 33 / 255.0,
        blue: 29 / 255.0
    )

    static let sage = Color(
        red: 168 / 255.0,
        green: 193 / 255.0,
        blue: 179 / 255.0
    )

    static var background: LinearGradient {
        LinearGradient(
            colors: [top, bottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// شاشة البداية الجديدة، ثم تنتقل إلى splash الموجودة عندكم.
struct DalLaunchView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var finished = false

    var body: some View {
        ZStack {
            DalLaunchPalette.background
                .ignoresSafeArea()

            if finished {
                splash()
                    .transition(.opacity)
            } else {
                DalIgnitionArtwork {
                    withAnimation(
                        .easeInOut(
                            duration: reduceMotion ? 0 : 0.6
                        )
                    ) {
                        finished = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

private struct DalIgnitionArtwork: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var appeared = false
    @State private var illuminated = false
    @State private var showName = false
    @State private var showTagline = false
    @State private var activeLights = 0
    @State private var needleAngle = 135.0
    @State private var started = false

    private let green = DalLaunchPalette.sage

    // تعديل العبارة يكون من هنا.
    private let tagline = "دَلّك على حال سيارتك"

    var body: some View {
        GeometryReader { geometry in
            let size = min(
                geometry.size.width * 0.78,
                310
            )

            ZStack {
                DalLaunchPalette.background

                // إضاءة هادئة خلف الرسم.
                Circle()
                    .fill(
                        green.opacity(
                            illuminated ? 0.08 : 0
                        )
                    )
                    .frame(
                        width: size * 1.05,
                        height: size * 1.05
                    )
                    .blur(radius: 55)
                    .offset(y: -45)

                VStack(spacing: 26) {
                    instruments(size: size)
                        .frame(
                            width: size,
                            height: size
                        )
                        .scaleEffect(
                            appeared ? 1 : 0.94
                        )
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 12) {
                        Text("دّل")
                            .font(
                                .system(
                                    size: 56,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)
                            .shadow(
                                color: green.opacity(0.12),
                                radius: 14
                            )
                            .opacity(showName ? 1 : 0)
                            .offset(
                                y: showName || reduceMotion
                                    ? 0 : 10
                            )

                        Text(tagline)
                            .font(
                                .system(
                                    size: 18,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(
                                DalLaunchPalette.sage
                            )
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .opacity(showTagline ? 1 : 0)
                            .offset(
                                y: showTagline || reduceMotion
                                    ? 0 : 6
                            )
                    }
                    .environment(
                        \.layoutDirection,
                        .rightToLeft
                    )
                }
                .offset(y: -20)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("دّل. \(tagline)")
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
        .task {
            await playIgnition()
        }
    }

    // رسم العدادات والمقود بالكود؛ لا يحتاج صورة في Assets.
    private func instruments(size: CGFloat) -> some View {
        ZStack {
            // العداد خلف المقود.
            ZStack {
                DalDialArc()
                    .stroke(
                        green.opacity(0.13),
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )

                DalDialArc()
                    .trim(from: 0, to: illuminated ? 1 : 0)
                    .stroke(
                        green,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .shadow(
                        color: green.opacity(0.3),
                        radius: 7
                    )

                ForEach(0..<31) { index in
                    Capsule()
                        .fill(
                            green.opacity(
                                illuminated ? 0.9 : 0.08
                            )
                        )
                        .frame(
                            width: index.isMultiple(of: 5)
                                ? 2.5 : 1.3,
                            height: index.isMultiple(of: 5)
                                ? 10 : 5
                        )
                        .offset(y: -size * 0.177)
                        .rotationEffect(
                            .degrees(-135 + Double(index) * 9)
                        )
                }

                Circle()
                    .stroke(
                        green.opacity(
                            illuminated ? 0.4 : 0.08
                        ),
                        lineWidth: 1
                    )
                    .padding(size * 0.055)

                Capsule()
                    .fill(green)
                    .frame(
                        width: size * 0.19,
                        height: 4
                    )
                    .offset(x: size * 0.075)
                    .rotationEffect(.degrees(needleAngle))
                    .shadow(
                        color: green.opacity(0.4),
                        radius: illuminated ? 5 : 0
                    )
                    .opacity(illuminated ? 1 : 0.1)

                Circle()
                    .fill(green)
                    .frame(width: 9, height: 9)
                    .opacity(illuminated ? 1 : 0.1)
            }
            .frame(
                width: size * 0.42,
                height: size * 0.42
            )
            .offset(y: -size * 0.08)

            // الرموز داخل محيط المقود.
            HStack(spacing: 12) {
                status(
                    "fuelpump.fill",
                    enabled: activeLights >= 1
                )

                status(
                    "battery.100percent",
                    enabled: activeLights >= 2
                )

                Spacer(minLength: 0)

                status(
                    "engine.combustion",
                    enabled: activeLights >= 3
                )
            }
            .padding(.horizontal, size * 0.16)
            .offset(y: -size * 0.08)

            // مقود فحمي محايد يحيط بالعداد.
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.24),
                            Color(white: 0.12),
                            Color(white: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.043
                )
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .frame(
                    width: size * 0.82,
                    height: size * 0.82
                )
                .offset(y: size * 0.08)

            // وسط المقود منخفض حتى لا يحجب العداد.
            DalWheelHub()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.22),
                            Color(white: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    DalWheelHub()
                        .stroke(
                            Color.white.opacity(0.17),
                            lineWidth: 1
                        )
                }
                .frame(
                    width: size * 0.78,
                    height: size * 0.24
                )
                .offset(y: size * 0.28)
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private func status(
        _ symbol: String,
        enabled: Bool
    ) -> some View {
        Image(systemName: symbol)
            .font(
                .system(
                    size: 15,
                    weight: .medium
                )
            )
            .foregroundStyle(
                green.opacity(enabled ? 1 : 0.1)
            )
            .shadow(
                color: green.opacity(
                    enabled ? 0.3 : 0
                ),
                radius: 5
            )
    }

    @MainActor
    private func playIgnition() async {
        guard !started else { return }
        started = true

        do {
            // احترام إعداد تقليل الحركة في الجهاز.
            if reduceMotion {
                appeared = true
                illuminated = true
                activeLights = 3
                showName = true
                showTagline = true
                needleAngle = 315

                try await Task.sleep(
                    nanoseconds: 1_500_000_000
                )
            } else {
                withAnimation(
                    .easeOut(duration: 0.8)
                ) {
                    appeared = true
                }

                try await Task.sleep(
                    nanoseconds: 300_000_000
                )

                withAnimation(
                    .easeInOut(duration: 1.0)
                ) {
                    illuminated = true
                }

                withAnimation(
                    .easeInOut(duration: 1.3)
                ) {
                    needleAngle = 405
                }

                for light in 1...3 {
                    try await Task.sleep(
                        nanoseconds: 280_000_000
                    )

                    withAnimation(
                        .easeOut(duration: 0.2)
                    ) {
                        activeLights = light
                    }
                }

                withAnimation(
                    .easeOut(duration: 0.7)
                ) {
                    showName = true
                }

                try await Task.sleep(
                    nanoseconds: 650_000_000
                )

                withAnimation(
                    .spring(
                        response: 0.8,
                        dampingFraction: 0.9
                    )
                ) {
                    needleAngle = 315
                }

                withAnimation(
                    .easeOut(duration: 0.7)
                ) {
                    showTagline = true
                }

                // وقت لقراءة الاسم والعبارة قبل الانتقال.
                try await Task.sleep(
                    nanoseconds: 2_600_000_000
                )
            }

            try Task.checkCancellation()
            onFinish()
        } catch {
            // إذا أُغلقت الشاشة يتوقف التسلسل.
        }
    }
}

// قوس العداد.
private struct DalDialArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.addArc(
            center: CGPoint(
                x: rect.midX,
                y: rect.midY
            ),
            radius: min(
                rect.width,
                rect.height
            ) / 2 - 3,
            startAngle: .degrees(135),
            endAngle: .degrees(405),
            clockwise: false
        )

        return path
    }
}

// شكل وسط المقود.
private struct DalWheelHub: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: 0,
                y: rect.height * 0.12
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.width,
                y: rect.height * 0.12
            ),
            control: CGPoint(
                x: rect.midX,
                y: -rect.height * 0.15
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.width * 0.88,
                y: rect.height * 0.46
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.width * 0.62,
                y: rect.height
            ),
            control: CGPoint(
                x: rect.width * 0.63,
                y: rect.height * 0.42
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.width * 0.38,
                y: rect.height
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.width * 0.12,
                y: rect.height * 0.46
            ),
            control: CGPoint(
                x: rect.width * 0.37,
                y: rect.height * 0.42
            )
        )

        path.closeSubpath()
        return path
    }
}

#Preview {
    DalLaunchView()
}
