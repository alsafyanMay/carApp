import SwiftUI

// Onboarding is a temporary root, never a destination in the navigation history.
struct SplashView: View {
    @AppStorage("hasCompletedOnboarding.v1") private var completed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CarVisualStyle.background.ignoresSafeArea()
            if completed {
                ContentView().transition(.opacity)
            } else {
                AcademyOnboarding(onFinish: finish).transition(.opacity)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .preferredColorScheme(.dark)
    }

    private func finish() {
        withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.25)) { completed = true }
    }
}

struct AcademyOnboarding: View {
    var initialPage = 0
    let onFinish: () -> Void
    @State private var page = 0
    @State private var movingForward = true
    @State private var pageWidth: CGFloat = 440
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 36.0
    @ScaledMetric(relativeTo: .title2) private var bodySize = 24.0

    private var pageTransition: AnyTransition {
        if reduceMotion { return .opacity }
        // In Arabic, the next page enters from the physical left; current exits right.
        return .asymmetric(
            insertion: .offset(x: movingForward ? -pageWidth : pageWidth).combined(with: .opacity),
            removal: .offset(x: movingForward ? pageWidth : -pageWidth).combined(with: .opacity))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
                    Button("تخطي", action: onFinish)
                        .font(.system(size: 22)).foregroundStyle(CarVisualStyle.secondaryText)
                        .frame(minWidth: 44, minHeight: 44)
                    Spacer()
                }
                .padding(.horizontal, 32)

                ViewThatFits(in: .vertical) {
                    pageContent(height: geometry.size.height)
                    ScrollView { pageContent(height: geometry.size.height) }
                }

                ZStack(alignment: .trailing) {
                    // Page-control dots sit close together (~16pt apart, like UIPageControl);
                    // the tap area stays tall, and each dot's hit area spans its 24pt slot.
                    HStack(spacing: 0) {
                        ForEach(0..<2) { index in
                            Button {
                                setPage(index)
                            } label: {
                                Circle().fill(page == index ? Color.white : Color.white.opacity(0.28))
                                    .frame(width: 8, height: 8)
                                    .frame(width: 24, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("الصفحة \(index + 1) من ٢")
                            .accessibilityAddTraits(page == index ? .isSelected : [])
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Button {
                        if page == 0 { setPage(1) } else { onFinish() }
                    } label: {
                        ZStack {
                            if page == 0 {
                                Image(systemName: "arrow.left").font(.system(size: 24, weight: .medium))
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            } else {
                                Text("ابدأ").font(.system(size: 22, weight: .medium))
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(width: page == 0 ? 48 : 72, height: 48)
                        .background(Capsule().fill(Color.white))
                    }
                    .accessibilityLabel(page == 0 ? "التالي" : "ابدأ")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .onAppear { pageWidth = geometry.size.width }
            .onChange(of: geometry.size.width) { _, width in pageWidth = width }
        }
        .onAppear { page = initialPage }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func pageContent(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if page == 0 {
                    // الصورة بحجم كانفس طولي وفيها حواف شفافة أعلى وأسفل، فنقصّها ونملأ العرض
                    Color.clear
                        .aspectRatio(1122 / 720, contentMode: .fit)
                        .overlay(
                            Image("Mirrored car with fuel and temperature cards Copy")
                                .resizable().scaledToFill()
                        )
                        .clipped()
                } else {
                    Image("Offline Bluetooth Car Link")
                        .resizable().scaledToFit()
                        .frame(height: min(320, height * 0.38))
                }
            }
                .frame(maxWidth: .infinity)
                // الصفحة الأولى: الصورة داخل الهوامش عشان ما تلمس حدود الجوال
                // الصفحة الثانية: تمتد بعرض الشاشة كاملًا (تتجاوز هامش الصفحة 20)
                .padding(.horizontal, page == 0 ? 12 : -20)
                .padding(.top, max(12, height * 0.07))
                .padding(.bottom, max(32, height * 0.09))
                .accessibilityHidden(true)
            Text(page == 0 ? "افهم سيارتك\nدون خبرة ميكانيكية" : "يعمل دون إنترنت")
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
            Text(page == 0
                 ? "نعرض لك أهم قراءات سيارتك، ونشرح ما تعنيه وما الذي تفعله بعدها، بلغة واضحة."
                 : "محوّل صغير يُركّب أسفل المقود، ويرسل القراءات إلى هاتفك عبر البلوتوث.")
                .font(.system(size: bodySize))
                .foregroundStyle(CarVisualStyle.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 24)
        }
        .multilineTextAlignment(.leading)
        // على الآيباد: عرض مريح يتوسّط الشاشة بدل التمدد الكامل
        .frame(maxWidth: 560, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .id(page)
        .transition(pageTransition)
    }

    private func setPage(_ next: Int) {
        guard next != page else { return }
        movingForward = next > page
        withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.3)) { page = next }
    }
}

#Preview("Onboarding — Arabic") { SplashView() }
