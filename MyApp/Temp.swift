// xcode: set sdk=iOS

// استيراد مكتبة SwiftUI
import SwiftUI

// ⭐ ملاحظة: الأشياء المساعدة في هالملف (الألوان، الخطوط، الصف، المؤشر، صفحة التجربة) كلها private
// يعني خاصة بالملف هذا بس، فالصفحات الأربع تقدر تستخدم نفس الأسماء بدون ما يصير تعارض

// MARK: - الألوان (نفسها في الصفحات الأربع)
private extension Color {
    // خلفية الصفحة
    static let pageBackground = Color(red: 23/255, green: 29/255, blue: 26/255)
    // خلفية الكروت والأقسام
    static let cardBackground = Color(red: 38/255, green: 43/255, blue: 40/255)
}

// MARK: - درجة الحالة (تحدد كل ألوان الصفحة)
private enum Tone {
    // خطر (أحمر)
    case danger
    // تنبيه (ذهبي)
    case warning
    // طبيعي (أخضر)
    case normal
    // معلومة (أزرق) — مثل المحرك البارد
    case info

    // لون أعلى الكرت الكبير
    var cardTop: Color {
        switch self {
        case .danger: return Color(red: 122/255, green: 58/255, blue: 66/255)
        case .warning: return Color(red: 122/255, green: 90/255, blue: 36/255)
        case .normal: return Color(red: 74/255, green: 107/255, blue: 78/255)
        case .info: return Color(red: 52/255, green: 83/255, blue: 122/255)
        }
    }

    // لون الأزرار
    var button: Color {
        switch self {
        case .danger: return Color(red: 154/255, green: 58/255, blue: 48/255)
        case .warning: return Color(red: 168/255, green: 130/255, blue: 58/255)
        case .normal: return Color(red: 63/255, green: 122/255, blue: 80/255)
        case .info: return Color(red: 62/255, green: 106/255, blue: 158/255)
        }
    }

    // لون فاتح للنصوص المهمة (نص التحذير وأرقام الخطوات)
    var accent: Color {
        switch self {
        case .danger: return Color(red: 242/255, green: 167/255, blue: 167/255)
        case .warning: return Color(red: 224/255, green: 178/255, blue: 90/255)
        case .normal: return Color(red: 143/255, green: 209/255, blue: 158/255)
        case .info: return Color(red: 156/255, green: 195/255, blue: 240/255)
        }
    }
}

// MARK: - الخطوط (نفسها في الصفحات الأربع)
// .system يستخدم خط النظام، وأي نص عربي يطلع تلقائيًا بخط SF Arabic
private enum AppFont {
    static let badge = Font.system(size: 13, weight: .medium)                // الشارة
    static let small = Font.system(size: 13, weight: .regular)               // الوقت
    static let title = Font.system(size: 22, weight: .bold)                  // العنوان
    static let subtitle = Font.system(size: 15, weight: .regular)            // النص تحت العنوان
    static let value = Font.system(size: 40, weight: .bold, design: .rounded) // الرقم الكبير
    static let unit = Font.system(size: 18, weight: .semibold)               // الوحدة جنب الرقم
    static let gaugeLabel = Font.system(size: 11, weight: .regular)          // عناوين الشريط
    static let warning = Font.system(size: 16, weight: .medium)              // صندوق التحذير
    static let rowTitle = Font.system(size: 18, weight: .semibold)           // "ماذا أفعل؟"
    static let rowBody = Font.system(size: 18, weight: .regular)             // الخطوات
    static let stepNumber = Font.system(size: 15, weight: .bold)             // رقم الخطوة
    static let button = Font.system(size: 17, weight: .semibold)             // الأزرار
    static let note = Font.system(size: 15, weight: .regular)                // جملة الطمأنة
    static let icon = Font.system(size: 60, weight: .regular)                // الأيقونة الكبيرة
}

// MARK: - حالة حرارة المحرك
// الحالات الثلاث (الداش بورد يستخدم هذا الـ enum بعد، عشان كذا مو private)
enum TempStatus {
    // أقل من 90: المحرك ما سخن
    case cold
    // من 90 إلى 105: طبيعي
    case normal
    // أعلى من 105: خطر
    case high

    // يحدد الحالة من القيمة
    init(temperature value: Double) {
        // switch يشيك المجالات بالترتيب
        switch value {
        case ..<90: self = .cold
        case ...105: self = .normal
        default: self = .high
        }
    }

    // نص الشارة الصغيرة
    var badgeText: String {
        switch self {
        case .cold: return "بارد"
        case .normal: return "طبيعي"
        case .high: return "خطر"
        }
    }

    // أيقونة الشارة
    var badgeIcon: String {
        switch self {
        case .cold: return "snowflake"
        case .normal: return "checkmark.circle"
        case .high: return "exclamationmark.triangle"
        }
    }
}

// MARK: - محتوى كل حالة (خاص بهالملف)
private extension TempStatus {
    // درجة الحالة (تحدد الألوان)
    var tone: Tone {
        switch self {
        case .cold: return .info
        case .normal: return .normal
        case .high: return .danger
        }
    }

    // ترتيب القسم في الشريط (0 يمين، 2 يسار)
    var index: Int {
        switch self {
        case .cold: return 0
        case .normal: return 1
        case .high: return 2
        }
    }

    // الأيقونة الكبيرة
    var icon: String {
        switch self {
        case .cold: return "thermometer.low"
        case .normal: return "thermometer.medium"
        case .high: return "thermometer.high"
        }
    }

    // العنوان
    var title: String {
        switch self {
        case .cold: return "المحرك لم يسخن بعد"
        case .normal: return "حرارة المحرك في الوضع الطبيعي"
        case .high: return "حرارة المحرك مرتفعة جدًا"
        }
    }

    // النص تحت العنوان
    var subtitle: String {
        switch self {
        case .cold: return "قُد بهدوء حتى تصل الحرارة إلى المعدل الطبيعي."
        case .normal: return "الحرارة ضمن المعدل الطبيعي."
        case .high: return "أوقف السيارة في مكان آمن خلال الدقائق القادمة."
        }
    }

    // الوقت اللي فوق يسار الكرت (نص مؤقت: لاحقًا يجي من وقت آخر قراءة)
    var timeText: String {
        switch self {
        case .cold: return "قبل دقيقة"
        case .normal: return "قبل دقيقة"
        case .high: return "بدأ قبل 4 دقائق"
        }
    }

    // نص صندوق التحذير (nil = ما فيه صندوق)
    var warning: String? {
        switch self {
        case .cold: return nil
        case .normal: return nil
        case .high: return "تجنّب فتح غطاء المبرّد (الرديتر) وهو ساخن."
        }
    }

    // خطوات "ماذا أفعل؟" (كل عنصر في المصفوفة = خطوة مرقّمة)
    var whatToDo: [String] {
        switch self {
        case .cold: return [
            "قُد بهدوء في الدقائق الأولى.",
            "تجنّب الضغط القوي على دواسة الوقود حتى تصل الحرارة إلى المعدل الطبيعي."
        ]
        case .normal: return [
            "لا يلزمك فعل شيء."
        ]
        case .high: return [
            "خفّف السرعة وشغّل أضواء التحذير.",
            "توقّف في مكان آمن وأطفئ المكيف.",
            "أطفئ المحرك وانتظر 15 دقيقة على الأقل قبل فحصه."
        ]
        }
    }

    // أسباب "ما السبب؟"
    var reason: [String] {
        switch self {
        case .cold: return [
            "بدأ المحرك العمل للتو ولم يصل إلى حرارة التشغيل بعد."
        ]
        case .normal: return [
            "نظام التبريد يعمل بشكل صحيح."
        ]
        case .high: return [
            "نقص سائل التبريد في المبرّد.",
            "عطل في مروحة التبريد.",
            "تسرّب في خراطيم التبريد."
        ]
        }
    }

    // هل نعرض زر الخريطة؟
    var showsMaps: Bool {
        switch self {
        case .cold: return false
        case .normal: return false
        case .high: return true
        }
    }
}

// MARK: - صفحة حرارة المحرك
struct EngineTempView: View {

    // القيمة تجي من برا (من الداش بورد أو صفحة التجربة)
    var temperature: Double = 118

    // الحالة تنحسب من القيمة كل ما تتغير
    private var status: TempStatus {
        TempStatus(temperature: temperature)
    }

    // هل قسم "ماذا أفعل؟" مفتوح
    @State private var showWhatToDo = false
    // هل قسم "ما السبب؟" مفتوح
    @State private var showWhy = false

    // أداة نفتح فيها الخرائط
    @Environment(\.openURL) private var openURL
    // أداة نسكّر فيها الشيت (لزر "حسنًا")
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // الخلفية تحت والمحتوى فوق
        ZStack {
            // لون الخلفية يغطي كل الشاشة
            Color.pageBackground
                .ignoresSafeArea()

            // ScrollView عشان المحتوى ينسحب لو طال
            ScrollView {
                // عمود فيه كل الصفحة
                VStack(spacing: 16) {
                    // الكرت الكبير
                    headerCard
                        // مسافة من فوق عشان ما يلصق بالشرطة
                        .padding(.top, 30)

                    if status == .normal {
                        // الحالة الطبيعية: جملة الطمأنة بس، والصفحة قصيرة
                        Text("القراءة مستقرة، ونواصل مراقبتها نيابةً عنك.")
                            .font(AppFont.note)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 20)
                            .transition(.opacity)
                    } else {
                        // غير الطبيعي: الصفحة كاملة
                        // مسافة بين الكرت والباقي
                        Spacer().frame(height: 16)
                        // صندوق التحذير لو فيه نص
                        if let warning = status.warning {
                            warningBox(warning)
                        }
                        // "ماذا أفعل؟"
                        ExpandableRow(title: "ماذا أفعل؟", items: status.whatToDo,
                                      accent: status.tone.accent, isExpanded: $showWhatToDo)
                        // "ما السبب؟"
                        ExpandableRow(title: "ما السبب؟", items: status.reason,
                                      accent: status.tone.accent, isExpanded: $showWhy)
                        // مسافة قبل الأزرار
                        Spacer().frame(height: 8)
                        // الأزرار (تتغير حسب الحالة)
                        buttons
                    }
                }
                // حواف الجوانب ومن تحت
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        // أي تغيير في الحالة يصير بحركة ناعمة
        .animation(.easeInOut(duration: 0.35), value: status)
        // اتجاه من اليمين لليسار
        .environment(\.layoutDirection, .rightToLeft)
        // الوضع الداكن
        .preferredColorScheme(.dark)
    }

    // MARK: - الكرت الكبير
    private var headerCard: some View {
        VStack(spacing: 12) {
            // السطر الأول: الشارة يمين والوقت يسار
            HStack {
                // الشارة
                HStack(spacing: 6) {
                    Image(systemName: status.badgeIcon)
                    Text(status.badgeText)
                }
                .font(AppFont.badge)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(.white.opacity(0.1)))

                // يدفع الوقت لليسار
                Spacer()

                // الوقت
                Text(status.timeText)
                    .font(AppFont.small)
                    .foregroundStyle(.white.opacity(0.8))
            }

            // الأيقونة الكبيرة (تتبدل بحركة لما تتغير الحالة)
            Image(systemName: status.icon)
                .font(AppFont.icon)
                .contentTransition(.symbolEffect(.replace))
                .padding(.top, 4)

            // العنوان
            Text(status.title)
                .font(AppFont.title)
                .multilineTextAlignment(.center)

            // النص تحت العنوان (ما يطلع في الحالة الطبيعية)
            if status != .normal {
                Text(status.subtitle)
                    .font(AppFont.subtitle)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // الرقم والوحدة جنب بعض (الوحدة تطلع يسار الرقم لأننا RTL)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                // الرقم (يتحرك مثل العداد لما يتغير)
                Text("\(Int(temperature))")
                    .font(AppFont.value)
                    .contentTransition(.numericText(value: temperature))
                // الوحدة
                Text("°م")
                    .font(AppFont.unit)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .animation(.snappy, value: temperature)
            .padding(.top, 4)

            // الشريط
            StatusGauge(value: temperature, active: status.index, knobColor: status.tone.cardTop)
                .padding(.top, 8)
        }
        // كل النصوص بيضاء
        .foregroundStyle(.white)
        // حواف داخلية
        .padding(20)
        // خلفية متدرجة من لون الحالة إلى لون الكروت
        .background(
            LinearGradient(colors: [status.tone.cardTop, .cardBackground],
                           startPoint: .top, endPoint: .bottom)
        )
        // زوايا دائرية
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - صندوق التحذير
    private func warningBox(_ text: String) -> some View {
        HStack(spacing: 12) {
            // أيقونة "ممنوع"
            Image(systemName: "nosign")
                .font(.system(size: 22, weight: .regular))
            // النص (fixedSize يخليه ينزل سطر جديد بدل ما ينقص)
            Text(text)
                .font(AppFont.warning)
                .fixedSize(horizontal: false, vertical: true)
            // يملأ باقي العرض
            Spacer(minLength: 0)
        }
        // لون النص والأيقونة: الفاتح حق الحالة
        .foregroundStyle(status.tone.accent)
        .padding(16)
        .frame(minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 20)
                // خلفية بلون الحالة شفافة
                .fill(status.tone.cardTop.opacity(0.35))
                // إطار خفيف بلون الحالة
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(status.tone.accent.opacity(0.3), lineWidth: 1)
                )
        )
        // يتلاشى ويصغر لما يطلع أو يختفي
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - الأزرار (تتغير حسب الحالة)
    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 12) {
            // زر الخريطة
            if status.showsMaps {
                mapsButton
            }
            // لو ما فيه زر خريطة، نعرض "حسنًا" عشان يسكّر الصفحة
            if !status.showsMaps {
                doneButton
            }
        }
    }

    // MARK: - زر "أقرب ورشة"
    // يفتح قوقل ماب ويبحث حول موقع المستخدم
    // تطبيقنا ما يحتاج نت، لكن البحث داخل الخريطة يحتاج داتا (إلا لو الخرائط محمّلة أوفلاين)
    private var mapsButton: some View {
        Button {
            // كلمة البحث، ونحوّل الحروف العربية لصيغة تنفع في الرابط
            let query = "ورشة سيارات".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            // رابط قوقل ماب
            let googleMaps = URL(string: "comgooglemaps://?q=\(query)")!
            // رابط خرائط أبل (احتياط لو قوقل ماب مو منزّل)
            let appleMaps = URL(string: "maps://?q=\(query)")!
            // نحاول قوقل ماب، ولو ما انفتح نفتح خرائط أبل
            openURL(googleMaps) { opened in
                if !opened { openURL(appleMaps) }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "map")
                Text("أقرب ورشة")
            }
            .primaryButtonStyle(color: status.tone.button)
        }
    }

    // MARK: - زر "حسنًا"
    private var doneButton: some View {
        Button {
            // نسكّر الشيت
            dismiss()
        } label: {
            Text("حسنًا")
                .primaryButtonStyle(color: status.tone.button)
        }
    }
}

// MARK: - شكل الأزرار (موحّد)
private extension View {
    // زر أساسي: خلفية مليانة
    func primaryButtonStyle(color: Color) -> some View {
        self
            .font(AppFont.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Capsule().fill(color))
            .shadow(color: color.opacity(0.4), radius: 10, y: 4)
    }

    // زر ثانوي: إطار بس
    func secondaryButtonStyle(color: Color) -> some View {
        self
            .font(AppFont.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(Capsule().stroke(color, lineWidth: 1.5))
    }
}

// MARK: - الشريط
private struct StatusGauge: View {
    // القيمة الحالية
    let value: Double
    // رقم القسم الحالي (0، 1، 2) عشان نلوّنه أبيض
    let active: Int
    // لون الدائرة
    let knobColor: Color

    // حدود الأقسام
    private let minValue: Double = 40    // بداية الشريط
    private let firstEnd: Double = 90     // نهاية القسم الأول
    private let secondEnd: Double = 105    // نهاية القسم الثاني
    private let maxValue: Double = 130    // نهاية الشريط

    // عرض كل قسم كنسبة من الشريط (الثالث ياخذ الباقي)
    private let firstWidth: Double = 0.55
    private let secondWidth: Double = 0.20
    private var thirdWidth: Double { 1 - firstWidth - secondWidth }

    // مكان الدائرة من 0 إلى 1 (كل قسم ينحسب لحاله عشان الحدود تطلع في مكانها بالضبط)
    private var progress: Double {
        let v = min(max(value, minValue), maxValue)
        switch v {
        case ..<firstEnd:
            return (v - minValue) / (firstEnd - minValue) * firstWidth
        case ..<secondEnd:
            return firstWidth + (v - firstEnd) / (secondEnd - firstEnd) * secondWidth
        default:
            return firstWidth + secondWidth + (v - secondEnd) / (maxValue - secondEnd) * thirdWidth
        }
    }

    // أبيض لو هو القسم الحالي، رمادي لو لا
    private func segmentColor(_ index: Int) -> Color {
        index == active ? .white : .gray.opacity(0.4)
    }

    var body: some View {
        VStack(spacing: 8) {
            // نقيس العرض المتاح
            GeometryReader { geo in
                // الدائرة فوق الشريط (leading = يمين في RTL)
                ZStack(alignment: .leading) {
                    // 3 أقسام جنب بعض
                    HStack(spacing: 3) {
                        Capsule().fill(segmentColor(0))
                            .frame(width: geo.size.width * firstWidth)
                        Capsule().fill(segmentColor(1))
                            .frame(width: geo.size.width * secondWidth)
                        Capsule().fill(segmentColor(2))
                    }
                    .frame(height: 6)

                    // الدائرة
                    Circle()
                        .fill(knobColor)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .frame(width: 18, height: 18)
                        .offset(x: progress * (geo.size.width - 18))
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20)

            // العناوين تحت الشريط
            HStack {
                Text("بارد")
                Spacer()
                Text("الطبيعي 90–105°")
                Spacer()
                Text("مرتفع")
            }
            .font(AppFont.gaugeLabel)
            .foregroundStyle(.white.opacity(0.7))
        }
        // الدائرة تتزحلق بنعومة
        .animation(.spring(duration: 0.4), value: value)
    }
}

// MARK: - صف ينفتح وينقفل ("ماذا أفعل؟" و "ما السبب؟")
private struct ExpandableRow: View {
    // العنوان
    let title: String
    // الخطوات (كل عنصر سطر مرقّم)
    let items: [String]
    // لون أرقام الخطوات
    let accent: Color
    // مفتوح أو لا (من الصفحة الأم)
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // العنوان والسهم
            HStack {
                Text(title)
                    .font(AppFont.rowTitle)
                Spacer()
                // السهم يلف لتحت لما ينفتح (90 مو -90 لأن الصفحة RTL)
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            // كامل الصف ينضغط
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }

            // المحتوى لما ينفتح
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    // خط فاصل بين العنوان والخطوات
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)

                    // enumerated يعطينا رقم كل عنصر (index) مع النص (item)
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        // كل خطوة في مربع لحالها عشان تكون مقسّمة وواضحة
                        HStack(alignment: .top, spacing: 12) {
                            // رقم الخطوة داخل دائرة
                            Text("\(index + 1)")
                                .font(AppFont.stepNumber)
                                .foregroundStyle(accent)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(accent.opacity(0.18)))
                            // نص الخطوة (ينزل سطر جديد لو طويل)
                            Text(item)
                                .font(AppFont.rowBody)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                            Spacer(minLength: 0)
                        }
                        // حواف داخلية للمربع
                        .padding(14)
                        // كامل العرض
                        .frame(maxWidth: .infinity)
                        // خلفية المربع: أفتح شوي من الكرت، بزوايا دائرية
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.05))
                        )
                        // خط جانبي رفيع بلون الحالة (على اليمين لأننا RTL)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.6))
                                .frame(width: 3)
                                .padding(.vertical, 10)
                        }
                    }
                }
                // يطلع بشفافية من فوق
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - صفحة التجربة (سلايدر + زر يفتح الصفحة كشيت)
private struct DemoView: View {
    // هل الشيت مفتوح
    @State private var showSheet = false
    // القيمة اللي نجربها
    @State private var value: Double = 118

    var body: some View {
        VStack(spacing: 24) {
            // القيمة الحالية
            Text("الحرارة: \(Int(value))°")
                .font(AppFont.title)
            // السلايدر
            Slider(value: $value, in: 40...130, step: 1)
            // زر يفتح الشيت
            Button("افتح الصفحة") { showSheet = true }
                .padding(.horizontal, 24)
                .primaryButtonStyle(color: Tone.normal.button)
            Spacer()
        }
        .padding(24)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showSheet) {
            EngineTempView(temperature: value)
                // نص الشاشة وكامل الشاشة
                .presentationDetents([.medium, .large])
                // السحب يحرّك الشيت أول
                .presentationContentInteraction(.resizes)
                // تقدر تحرك السلايدر والشيت على النص
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                // الشرطة فوق (المستخدم يسحب لتحت عشان يسكّر)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
                .presentationBackground(Color.pageBackground)
        }
    }
}

// MARK: - المعاينات
#Preview("حرارة - تجربة") { DemoView() }
#Preview("حرارة - مرتفع") { EngineTempView(temperature: 118) }
#Preview("حرارة - طبيعي") { EngineTempView(temperature: 96) }
#Preview("حرارة - بارد") { EngineTempView(temperature: 60) }
