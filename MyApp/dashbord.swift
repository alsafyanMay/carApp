// xcode: set sdk=iOS

// استيراد مكتبة SwiftUI
import SwiftUI

// ⚠️ هذي الصفحة تفتح صفحاتك الأربع، فلازم يكونون في نفس المشروع:
// EngineTempView.swift و BatteryView.swift و FuelView.swift
// وتستخدم الحالات اللي فيهم (TempStatus و BatteryStatus و FuelStatus)
// القيم تجي من cartype.swift (من obdService.vehicleData)، وتتحدث لحالها كل ما وصلت قراءة جديدة

// MARK: - ألوان الداش بورد
// الأسماء تبدأ بـ dash عشان ما تتعارض مع ألوان الصفحات الثانية
extension Color {
    // الأخضر الغامق في أعلى الخلفية
    static let dashTop = Color(red: 47/255, green: 61/255, blue: 54/255)
    // الأسود المخضر في أسفل الخلفية
    static let dashBottom = Color(red: 22/255, green: 26/255, blue: 24/255)
    // خلفية الكروت الصغيرة
    static let dashCard = Color(red: 27/255, green: 32/255, blue: 29/255)
    // خلفية الشيت (نفس خلفية صفحاتك)
    static let dashSheet = Color(red: 22/255, green: 29/255, blue: 26/255)
}

// MARK: - درجة الخطورة
// كل قياس نحوّل حالته لوحدة من هذي، وكل وحدة لها لونها
// كذا الداش بورد يلوّن كل الكروت بنفس الطريقة
enum DashTone {
    // خطر (وردي/أحمر)
    case danger
    // تنبيه (ذهبي)
    case warning
    // طبيعي (أخضر)
    case normal
    // معلومة (أزرق) — مثل المحرك البارد
    case info
    // ما فيه قراءة (رمادي) — السيارة ما تدعمها أو ما وصلت للحين
    case idle

    // اللون الأساسي (للإطار والشارة والأيقونة)
    var color: Color {
        switch self {
        case .danger: return Color(red: 201/255, green: 138/255, blue: 147/255)
        case .warning: return Color(red: 201/255, green: 150/255, blue: 46/255)
        case .normal: return Color(red: 63/255, green: 163/255, blue: 77/255)
        case .info: return Color(red: 91/255, green: 143/255, blue: 217/255)
        case .idle: return Color.gray
        }
    }

    // اللون الغامق (لأعلى الكرت العريض)
    var dark: Color {
        switch self {
        case .danger: return Color(red: 107/255, green: 43/255, blue: 48/255)
        case .warning: return Color(red: 90/255, green: 65/255, blue: 20/255)
        case .normal: return Color(red: 30/255, green: 70/255, blue: 45/255)
        case .info: return Color(red: 30/255, green: 50/255, blue: 85/255)
        case .idle: return Color(red: 45/255, green: 50/255, blue: 48/255)
        }
    }
}

// MARK: - أي صفحة مفتوحة
// enum يحدد أي صفحة نفتحها كشيت (Identifiable مطلوب لـ .sheet(item:))
enum DashSheet: Identifiable {
    case temperature, battery, fuel
    // كل حالة هي نفسها الـ id
    var id: Self { self }
}

// MARK: - صفحة الداش بورد
struct DashboardView: View {

    // MARK: القيم (تجي من برا: cartype يرسلها من obdService.vehicleData)
    // Double? يعني ممكن تكون nil = السيارة ما تدعم القراءة أو ما وصلت للحين
    var coolantTemp: Double? = nil     // حرارة المحرك
    var fuelLevel: Double? = nil       // نسبة الوقود
    var batteryVoltage: Double? = nil  // جهد البطارية
    // هل الاتصال بالسيارة شغّال؟
    var isConnected: Bool = true
    // وش يصير لما يضغط "إعادة الاتصال" (cartype يرجّعه لصفحة اختيار السيارة)
    var onReconnect: () -> Void = {}

    // الصفحة المفتوحة حاليًا (nil = ما فيه شي مفتوح)
    @State private var activeSheet: DashSheet?

    // MARK: الحالات (نحسبها من القيم، و nil لو ما فيه قراءة)
    // map: لو القيمة موجودة نحوّلها لحالة، لو nil تبقى nil
    private var tempStatus: TempStatus? { coolantTemp.map { TempStatus(temperature: $0) } }
    private var batteryStatus: BatteryStatus? { batteryVoltage.map { BatteryStatus(voltage: $0) } }
    private var fuelStatus: FuelStatus? { fuelLevel.map { FuelStatus(level: $0) } }

    // MARK: درجة الخطورة لكل قياس
    private var tempTone: DashTone {
        // ما فيه قراءة → رمادي
        guard let tempStatus else { return .idle }
        switch tempStatus {
        case .cold: return .info       // بارد → أزرق
        case .normal: return .normal   // طبيعي → أخضر
        case .high: return .danger     // مرتفع → أحمر
        }
    }
    private var batteryTone: DashTone {
        // ما فيه قراءة → رمادي
        guard let batteryStatus else { return .idle }
        switch batteryStatus {
        case .low: return .warning     // منخفض → ذهبي (مثل صفحة البطارية)
        case .normal: return .normal   // طبيعي → أخضر
        case .high: return .danger     // شحن زائد → أحمر
        }
    }
    private var fuelTone: DashTone {
        // ما فيه قراءة → رمادي
        guard let fuelStatus else { return .idle }
        switch fuelStatus {
        case .critical: return .danger // على وشك ينفد → أحمر
        case .low: return .warning     // منخفض → ذهبي
        case .normal: return .normal   // كافي → أخضر
        }
    }
    // MARK: الرسالة اللي في أسفل الكروت العريضة
    private var tempMessage: String {
        guard let tempStatus else { return "القراءة غير متاحة لهذه السيارة" }
        switch tempStatus {
        case .cold: return "المحرك لم يصل إلى حرارة التشغيل بعد"
        case .normal: return "الحرارة ضمن المعدل الطبيعي"
        case .high: return "توقّف في مكان آمن وأطفئ المحرك"
        }
    }
    var body: some View {
        // ZStack: الخلفية تحت والمحتوى فوق
        ZStack {
            // خلفية متدرجة من الأخضر الغامق للأسود
            LinearGradient(colors: [.dashTop, .dashBottom], startPoint: .top, endPoint: .bottom)
                // تغطي كل الشاشة
                .ignoresSafeArea()

            // ScrollView عشان لو الشاشة صغيرة المحتوى ينسحب
            ScrollView {
                // عمود فيه كل الصفحة
                VStack(spacing: 0) {
                    // العنوان الرئيسي
                    Text("حالة السيارة")
                        // خط كبير وعريض
                        .font(.system(size: 32, weight: .bold))
                        // مسافة من فوق
                        .padding(.top, 40)

                    // حالة الاتصال
                    Text(isConnected ? "سيارتك متصلة وجاهزة للفحص" : "انقطع الاتصال بالسيارة")
                        // خط متوسط
                        .font(.title3)
                        // لون أفتح شوي
                        .foregroundStyle(.white.opacity(0.9))
                        // مسافة من فوق
                        .padding(.top, 20)

                    // لو انقطع الاتصال: زر يرجّع المستخدم يتصل من جديد
                    if !isConnected {
                        Button("إعادة الاتصال", action: onReconnect)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.12)))
                            .padding(.top, 12)
                    }

                    // عنوان القسم
                    Text("صحة السيارة")
                        // خط كبير وعريض
                        .font(.system(size: 30, weight: .bold))
                        // على اليمين
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // مسافات
                        .padding(.top, 50)
                        .padding(.bottom, 16)

                    // 1️⃣ كرت الحرارة العريض
                    Button { activeSheet = .temperature } label: {
                        DashWideCard(
                            icon: "thermometer.medium",                         // أيقونة الثيرمومتر
                            title: "حرارة المحرك",                              // العنوان
                            value: coolantTemp.map { "\(Int($0))" } ?? "--",   // الرقم (أو -- لو ما فيه قراءة)
                            unit: "°م",                                         // الوحدة
                            badgeText: tempStatus?.badgeText,                   // الشارة (من صفحة الحرارة)
                            badgeIcon: tempStatus?.badgeIcon ?? "",             // أيقونة الشارة
                            message: tempMessage,                               // الرسالة تحت
                            tone: tempTone                                      // اللون
                        )
                    }
                    // لو ما فيه قراءة، الكرت ما ينضغط
                    .disabled(coolantTemp == nil)

                    // 2️⃣ صف فيه الوقود والبطارية جنب بعض
                    HStack(spacing: 12) {
                        // الوقود (أول عنصر = يمين)
                        Button { activeSheet = .fuel } label: {
                            DashSmallCard(
                                icon: "fuelpump",                                   // أيقونة المضخة
                                title: "الوقود",                                     // العنوان
                                value: fuelLevel.map { "\(Int($0))" } ?? "--",     // الرقم
                                unit: "%",                                           // الوحدة
                                badgeText: fuelStatus?.badgeText,                    // الشارة
                                badgeIcon: fuelStatus?.badgeIcon ?? "",              // أيقونة الشارة
                                tone: fuelTone,                                      // اللون
                                progress: (fuelLevel ?? 0) / 100                     // الشريط من 0 إلى 1
                            )
                        }
                        .disabled(fuelLevel == nil)
                        // البطارية (يسار)
                        Button { activeSheet = .battery } label: {
                            DashSmallCard(
                                icon: "bolt.fill",                                                  // أيقونة البرق
                                title: "البطارية",                                                   // العنوان
                                value: batteryVoltage.map { String(format: "%.1f", $0) } ?? "--",  // الرقم بخانة عشرية
                                unit: "فولت",                                                        // الوحدة
                                badgeText: batteryStatus?.badgeText,                                 // الشارة
                                badgeIcon: batteryStatus?.badgeIcon ?? "",                           // أيقونة الشارة
                                tone: batteryTone,                                                   // اللون
                                progress: ((batteryVoltage ?? 11.5) - 11.5) / (16 - 11.5)            // 11.5 فولت فاضي، 16 فل
                            )
                        }
                        .disabled(batteryVoltage == nil)
                    }
                    // مسافة من فوق
                    .padding(.top, 16)

                    // الجملة اللي في آخر الصفحة
                    Text("- رحلتك أكثر أمانًا -")
                        // خط صغير وعريض
                        .font(.subheadline.weight(.semibold))
                        // مسافة من فوق وتحت
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                }
                // حواف الصفحة من الجوانب
                .padding(.horizontal, 12)
            }
            // كل الأزرار بدون شكلها الافتراضي (الأزرق)
            .buttonStyle(.plain)
            // لون كل النصوص أبيض
            .foregroundStyle(.white)
        }
        // اتجاه من اليمين لليسار
        .environment(\.layoutDirection, .rightToLeft)
        // الوضع الداكن
        .preferredColorScheme(.dark)
        // لو انقطع الاتصال وفيه صفحة تفاصيل مفتوحة، نسكّرها (عشان ما تعرض 0 بدل القراءة)
        .onChange(of: isConnected) { _, connected in
            if !connected { activeSheet = nil }
        }
        // الشيت: يفتح الصفحة المطلوبة ويرسل لها القيمة
        .sheet(item: $activeSheet) { sheet in
            // نختار الصفحة حسب الكرت اللي انضغط
            Group {
                switch sheet {
                // ?? 0 للاحتياط بس: الكرت أصلًا ما ينضغط لو القيمة nil
                case .temperature: EngineTempView(temperature: coolantTemp ?? 0)
                case .battery: BatteryView(voltage: batteryVoltage ?? 0)
                case .fuel: FuelView(level: fuelLevel ?? 0)
                }
            }
            // نص الشاشة وكامل الشاشة
            .presentationDetents([.medium, .large])
            // السحب يحرّك الشيت أول
            .presentationContentInteraction(.resizes)
            // الشرطة فوق (الصفحات ما فيها زر X، فالمستخدم يسحب لتحت عشان يسكّر)
            .presentationDragIndicator(.visible)
            // زوايا دائرية
            .presentationCornerRadius(40)
            // لون الخلفية
            .presentationBackground(Color.dashSheet)
        }
    }
}

// MARK: - الكرت العريض (الحرارة)
struct DashWideCard: View {
    let icon: String        // أيقونة SF Symbol
    let title: String       // العنوان
    let value: String       // الرقم كنص
    let unit: String        // الوحدة
    let badgeText: String?  // نص الشارة (nil = ما تطلع)
    let badgeIcon: String   // أيقونة الشارة
    let message: String     // الرسالة تحت الخط
    let tone: DashTone      // درجة الخطورة (تحدد الألوان)

    var body: some View {
        // عمود فيه محتوى الكرت
        VStack(alignment: .leading, spacing: 14) {
            // السطر الأول: الأيقونة والعنوان يمين، والشارة يسار
            HStack {
                // مربع الأيقونة
                DashIconBox(icon: icon, color: tone.color)
                // العنوان
                Text(title)
                    // خط متوسط
                    .font(.title3)
                    // لون أفتح شوي
                    .foregroundStyle(.white.opacity(0.85))
                // يدفع الشارة لليسار
                Spacer()
                // الشارة لو فيه نص
                if let badgeText {
                    DashBadge(text: badgeText, icon: badgeIcon, color: tone.color)
                }
            }

            // الرقم والوحدة
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                // الرقم
                Text(value)
                    // خط كبير وعريض
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    // يتحرك مثل العداد لما يتغير
                    .contentTransition(.numericText())
                // الوحدة
                Text(unit)
                    // خط صغير
                    .font(.subheadline)
                    // لون باهت
                    .foregroundStyle(.white.opacity(0.7))
            }
            // نزحزح الرقم شوي لداخل مثل التصميم
            .padding(.leading, 40)

            // خط فاصل
            Rectangle()
                // أبيض شفاف
                .fill(.white.opacity(0.4))
                // سماكة 1
                .frame(height: 1)

            // الرسالة والسهم
            HStack {
                // الرسالة
                Text(message)
                    // خط عريض
                    .font(.headline)
                // يدفع السهم لليسار
                Spacer()
                // السهم
                Image(systemName: "chevron.left")
                    // خط عريض
                    .font(.headline)
            }
        }
        // حواف داخلية
        .padding(16)
        // خلفية متدرجة من لون الخطورة الغامق للأسود
        .background(
            LinearGradient(colors: [tone.dark, Color.dashCard], startPoint: .top, endPoint: .bottom)
        )
        // زوايا دائرية
        .clipShape(RoundedRectangle(cornerRadius: 22))
        // إطار بلون الخطورة
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(tone.color.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - الكرت الصغير (الوقود والبطارية)
struct DashSmallCard: View {
    let icon: String        // أيقونة SF Symbol
    let title: String       // العنوان
    let value: String       // الرقم كنص
    let unit: String        // الوحدة
    let badgeText: String?  // نص الشارة (nil = ما تطلع)
    let badgeIcon: String   // أيقونة الشارة
    let tone: DashTone      // درجة الخطورة
    let progress: Double    // نسبة الشريط من 0 إلى 1

    var body: some View {
        // عمود فيه محتوى الكرت
        VStack(alignment: .leading, spacing: 10) {
            // السطر الأول: الأيقونة يمين والشارة يسار
            HStack {
                // مربع الأيقونة
                DashIconBox(icon: icon, color: tone.color)
                // فراغ
                Spacer()
                // الشارة لو فيه نص
                if let badgeText {
                    DashBadge(text: badgeText, icon: badgeIcon, color: tone.color)
                }
            }

            // العنوان بلون الخطورة
            Text(title)
                // خط متوسط
                .font(.headline)
                // بلون الخطورة
                .foregroundStyle(tone.color)

            // الرقم والوحدة
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                // الرقم
                Text(value)
                    // خط كبير
                    .font(.system(size: 34, weight: .regular, design: .rounded))
                    // يتحرك مثل العداد
                    .contentTransition(.numericText())
                // الوحدة
                Text(unit)
                    // خط صغير جدًا
                    .font(.caption2)
                    // لون باهت
                    .foregroundStyle(.white.opacity(0.6))
            }
            // بالوسط
            .frame(maxWidth: .infinity)

            // شريط التقدم
            DashProgressBar(progress: progress, color: tone.color)

            // خط فاصل
            Rectangle()
                // أبيض شفاف
                .fill(.white.opacity(0.25))
                // سماكة 1
                .frame(height: 1)
                // مسافة من فوق
                .padding(.top, 6)

            // السهم بلون الخطورة
            Image(systemName: "chevron.left")
                // خط عريض
                .font(.headline)
                // بلون الخطورة
                .foregroundStyle(tone.color)
        }
        // حواف داخلية
        .padding(12)
        // الخلفية
        .background(
            ZStack {
                // لون غامق
                Color.dashCard
                // توهج بلون الخطورة يطلع من تحت
                RadialGradient(
                    colors: [tone.color.opacity(0.45), .clear], // من اللون إلى شفاف
                    center: .bottom,                            // المركز تحت
                    startRadius: 0,                             // يبدأ من المركز
                    endRadius: 160                              // وينتهي على بعد 160
                )
            }
        )
        // زوايا دائرية
        .clipShape(RoundedRectangle(cornerRadius: 22))
        // إطار بلون الخطورة
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(tone.color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - مربع الأيقونة الصغير
struct DashIconBox: View {
    let icon: String  // اسم الأيقونة
    let color: Color  // اللون

    var body: some View {
        // الأيقونة
        Image(systemName: icon)
            // حجمها
            .font(.system(size: 16, weight: .semibold))
            // لونها
            .foregroundStyle(color)
            // مقاس المربع
            .frame(width: 30, height: 30)
            // خلفية بنفس اللون بس شفافة
            .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.25)))
    }
}

// MARK: - الشارة
struct DashBadge: View {
    let text: String  // النص
    let icon: String  // الأيقونة
    let color: Color  // اللون

    var body: some View {
        // أيقونة ونص جنب بعض
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        // خط صغير
        .font(.caption.weight(.medium))
        // لون أبيض
        .foregroundStyle(.white)
        // حواف داخلية
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        // خلفية كبسولة بلون الشارة
        .background(Capsule().fill(color.opacity(0.55)))
    }
}

// MARK: - شريط التقدم
struct DashProgressBar: View {
    let progress: Double  // النسبة من 0 إلى 1
    let color: Color      // لون الجزء المعبّى

    var body: some View {
        // نقيس العرض المتاح
        GeometryReader { geo in
            // نتأكد إن النسبة بين 0 و 1
            let p = min(max(progress, 0), 1)
            // يبدأ من اليمين (leading في RTL)
            ZStack(alignment: .leading) {
                // الشريط الفاضي
                Capsule().fill(.white.opacity(0.15))
                    .frame(height: 5)
                // الجزء المعبّى
                Capsule().fill(color)
                    .frame(width: geo.size.width * p, height: 5)
                // المؤشر الصغير في نهاية الجزء المعبّى
                Capsule().fill(color)
                    .frame(width: 4, height: 12)
                    .offset(x: geo.size.width * p - 2)
            }
            // بالنص عموديًا
            .frame(maxHeight: .infinity)
        }
        // ارتفاع المساحة
        .frame(height: 12)
        // الشريط يتحرك بنعومة
        .animation(.spring(duration: 0.4), value: progress)
    }
}

// MARK: - المعاينات
// بقيم تجريبية (مثل التصميم)
#Preview("داش بورد") {
    DashboardView(coolantTemp: 118, fuelLevel: 20, batteryVoltage: 14.0)
}

// السيارة ما تدعم أي قراءة، أو الاتصال انقطع
#Preview("داش بورد - بدون قراءات") {
    DashboardView(isConnected: false)
}
