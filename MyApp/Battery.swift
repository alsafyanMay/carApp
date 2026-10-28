// xcode: set sdk=iOS

// استيراد مكتبة SwiftUI
import SwiftUI
// مكتبة الإشعارات المحلية (يجدولها الجوال نفسه، فتشتغل بدون إنترنت)
import UserNotifications

// MARK: - ألوان صفحة البطارية
// الملف هذا مستقل: كل اللي يحتاجه موجود فيه، فيشتغل لحاله حتى لو ما فيه ملفات ثانية
// الأسماء كلها تبدأ بـ bat عشان ما تتعارض مع ألوان الملفات الثانية لو حطيتهم في نفس المشروع
extension Color {
    // لون خلفية الشاشة
    static let batBackground = Color(red: 22/255, green: 29/255, blue: 26/255)
    // لون خلفية الكروت
    static let batCard = Color(red: 41/255, green: 46/255, blue: 43/255)
    // أحمر غامق لحالة المنخفض
    static let batDanger = Color(red: 130/255, green: 65/255, blue: 74/255)
    // أخضر لحالة الطبيعي
    static let batNormal = Color(red: 45/255, green: 100/255, blue: 70/255)
    // برتقالي غامق لحالة الشحن الزائد
    static let batAmber = Color(red: 150/255, green: 95/255, blue: 30/255)
    // أحمر فاتح لنص التحذير
    static let batWarningText = Color(red: 255/255, green: 180/255, blue: 172/255)
}

// MARK: - حالة البطارية
// enum فيه الحالات الثلاث، وكل حالة لها نصوصها وألوانها
enum BatteryStatus {
    // أقل من 13.2 فولت: الدينمو ما يشحن
    case low
    // من 13.2 إلى 14.8 فولت: الشحن تمام
    case normal
    // أعلى من 14.8 فولت: شحن زائد
    case high

    // init يحدد الحالة من جهد البطارية
    init(voltage: Double) {
        // switch يشيك الرقم على المجالات بالترتيب
        switch voltage {
        // ..<13.2 يعني أي رقم أقل من 13.2
        case ..<13.2: self = .low
        // ...14.8 يعني أي رقم لين 14.8 (والأقل من 13.2 انمسك فوق)
        case ...14.8: self = .normal
        // أي شي غير كذا يعني أعلى من 14.8
        default: self = .high
        }
    }

    // نص الشارة الصغيرة اللي فوق يمين الكرت
    var badgeText: String {
        switch self {
        case .low: return "منخفض"
        case .normal: return "طبيعي"
        case .high: return "مرتفع"
        }
    }

    // أيقونة الشارة
    var badgeIcon: String {
        switch self {
        case .low: return "exclamationmark.triangle"   // مثلث تحذير
        case .normal: return "checkmark.circle"        // علامة صح
        case .high: return "exclamationmark.triangle"  // مثلث تحذير
        }
    }

    // الأيقونة الكبيرة: بطارية السيارة (بأقطاب + و −)
    var icon: String {
        switch self {
        case .low: return "minus.plus.batteryblock.exclamationmark"    // بطارية + علامة تعجب
        case .normal: return "minus.plus.batteryblock"                 // بطارية عادية
        case .high: return "minus.plus.batteryblock.exclamationmark"   // بطارية + علامة تعجب
        }
    }

    // العنوان الرئيسي
    var title: String {
        switch self {
        case .low: return "البطارية لا تُشحن"
        case .normal: return "البطارية في الوضع الطبيعي"
        case .high: return "شحن زائد للبطارية"
        }
    }

    // النص تحت العنوان
    var subtitle: String {
        switch self {
        case .low: return "قد تتوقف السيارة عن العمل، توجّه إلى أقرب ورشة في أسرع وقت."
        case .normal: return "الشحن يعمل بشكل سليم، تابع طريقك."
        case .high: return "الجهد أعلى من المعدل الطبيعي، وهذا يضر بالبطارية والأجزاء الكهربائية."
        }
    }

    // لون أعلى الكرت
    var color: Color {
        switch self {
        case .low: return .batDanger     // أحمر
        case .normal: return .batNormal // أخضر
        case .high: return .batAmber  // برتقالي
        }
    }

    // نص صندوق التحذير (String? يعني ممكن يكون فاضي nil، وهنا الطبيعي ما له تحذير)
    var warning: String? {
        switch self {
        case .low: return "لا تُطفئ السيارة إلا في مكان آمن، فقد لا تعمل مرة أخرى."
        case .normal: return nil
        case .high: return "انتبه لأي رائحة احتراق أو سخونة في البطارية."
        }
    }

    // محتوى "ماذا أفعل؟"
    var whatToDo: String {
        switch self {
        case .low: return "١. أطفئ المكيف والمذياع والأنوار غير الضرورية.\n٢. لا تُطفئ المحرك حتى تصل إلى وجهتك.\n٣. توجّه إلى أقرب ورشة."
        case .normal: return "لا يلزمك فعل شيء."
        case .high: return "١. لا تُطِل مدة القيادة.\n٢. افحص المولّد (الدينمو) في أقرب فرصة."
        }
    }

    // محتوى "ما السبب؟"
    var reason: String {
        switch self {
        case .low: return "غالبًا بسبب عطل في المولّد (الدينمو)، أو انقطاع سيره أو ارتخائه، أو اتساخ أطراف البطارية."
        case .normal: return "المولّد يشحن البطارية بشكل صحيح."
        case .high: return "غالبًا بسبب عطل في منظّم الجهد الخاص بالمولّد."
        }
    }

    // نص إشعار التذكير
    var reminderText: String {
        switch self {
        case .low: return "لا تنسَ فحص المولّد والبطارية في الورشة."
        case .normal: return ""
        case .high: return "لا تنسَ فحص منظّم الجهد في المولّد."
        }
    }
}

// MARK: - صفحة البطارية
struct BatteryView: View {

    // جهد البطارية يجي من برا (من الصفحة اللي تفتح الشيت)
    // = 14.3 قيمة افتراضية لو ما أرسلت شي
    var voltage: Double = 14.3

    // خاصية محسوبة: كل ما يتغير الجهد تنحسب الحالة من جديد
    private var status: BatteryStatus {
        BatteryStatus(voltage: voltage)
    }

    // هل قسم "ماذا أفعل؟" مفتوح
    @State private var showWhatToDo = false
    // هل قسم "ما السبب؟" مفتوح
    @State private var showWhy = false

    // وقت التذكير المحفوظ (بالثواني من 1970، و 0 يعني ما فيه تذكير)
    // @AppStorage يحفظه في الجوال، فيبقى حتى لو سكّر التطبيق
    @AppStorage("batteryReminder") private var reminderTime: Double = 0

    // أداة نفتح فيها تطبيق ثاني (قوقل ماب أو خرائط أبل)
    @Environment(\.openURL) private var openURL


    var body: some View {
        // ZStack: الخلفية تحت والمحتوى فوق
        ZStack {
            // لون الخلفية
            Color.batBackground
                // يغطي كل الشاشة
                .ignoresSafeArea()

            // ScrollView عشان المحتوى ينسحب
            ScrollView {
                // عمود فيه كل محتوى الصفحة
                VStack(spacing: 20) {
                    // الكرت الكبير
                    headerCard
                        // مسافة من فوق عشان ما يلصق بالشرطة
                        .padding(.top, 50)
                    // لو الحالة طبيعية (أخضر): نعرض جملة الطمأنة بس، والصفحة تكون قصيرة
                    if status == .normal {
                        // الجملة
                        Text("القراءة مستقرة، ونواصل مراقبتها نيابةً عنك.")
                            // خط عادي
                            .font(.subheadline)
                            // لون أفتح شوي
                            .foregroundStyle(.white.opacity(0.9))
                            // مسافة من فوق
                            .padding(.top, 24)
                            // يتلاشى لما يطلع أو يختفي
                            .transition(.opacity)
                    } else {
                        // غير كذا: الصفحة كاملة (تحذير + الأقسام + زر التذكير)
                        // مسافة بين الكرت والباقي
                        Spacer().frame(height: 30)
                        // if let: لو فيه نص تحذير (مو nil) نحطه في warningText ونعرض الصندوق
                        if let warningText = status.warning {
                            // صندوق التحذير
                            warningBox(warningText)
                        }
                        // "ماذا أفعل؟"
                        BatteryExpandableRow(title: "ماذا أفعل؟", isExpanded: $showWhatToDo) {
                            // النص حسب الحالة
                            Text(status.whatToDo)
                        }
                        // "ما السبب؟"
                        BatteryExpandableRow(title: "ما السبب؟", isExpanded: $showWhy) {
                            // النص حسب الحالة
                            Text(status.reason)
                        }
                        // مسافة قبل الزر
                        Spacer().frame(height: 10)
                        // زر "أقرب ورشة" (الأساسي)
                        workshopButton
                        // زر "ذكّرني" (الثانوي) يطلع بس لما يكون الجهد منخفض
                        if status == .low {
                            reminderButton
                        }
                    }
                }
                // حواف من الجوانب
                .padding(.horizontal, 20)
                // حافة من تحت
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

    // MARK: - الكرت الرئيسي
    private var headerCard: some View {
        // عمود فيه محتوى الكرت
        VStack(spacing: 12) {
            // السطر العلوي: الشارة + الوقت
            HStack {
                // الشارة
                HStack(spacing: 6) {
                    // أيقونة الشارة حسب الحالة
                    Image(systemName: status.badgeIcon)
                    // نص الشارة حسب الحالة
                    Text(status.badgeText)
                }
                // خط صغير
                .font(.footnote)
                // حواف داخلية
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                // خلفية كبسولة شفافة
                .background(Capsule().fill(.white.opacity(0.08)))

                // يدفع الوقت لليسار
                Spacer()

                // نص الوقت
                // (نص مؤقت: لاحقًا يجي من وقت آخر قراءة)
                Text(status == .normal ? "قبل دقيقة" : "بدأ قبل 4 دقائق")
                    // خط صغير
                    .font(.footnote)
                    // لون باهت
                    .foregroundStyle(.white.opacity(0.8))
            }

            // الأيقونة الكبيرة حسب الحالة
            Image(systemName: status.icon)
                // حجم كبير
                .font(.system(size: 64, weight: .regular))
                // تتبدل بحركة لما تتغير
                .contentTransition(.symbolEffect(.replace))
                // مسافة من فوق
                .padding(.top, 4)

            // العنوان حسب الحالة
            Text(status.title)
                // خط كبير وعريض
                .font(.title2.bold())

            // النص التوضيحي حسب الحالة (ما يطلع في الحالة الطبيعية، مثل التصميم)
            if status != .normal {
                Text(status.subtitle)
                    // خط متوسط
                    .font(.subheadline)
                    // لون أفتح شوي
                    .foregroundStyle(.white.opacity(0.9))
                    // بالوسط لو نزل سطرين
                    .multilineTextAlignment(.center)
            }

            // رقم الجهد: %.1f يعني رقم بخانة عشرية وحدة (14.3)
            Text("\(String(format: "%.1f", voltage)) فولت")
                // خط كبير وعريض
                .font(.system(size: 36, weight: .bold, design: .rounded))
                // الأرقام تتحرك مثل العداد لما تتغير
                .contentTransition(.numericText(value: voltage))
                // الحركة نفسها
                .animation(.snappy, value: voltage)
                // مسافة من فوق
                .padding(.top, 4)

            // مؤشر الجهد
            BatteryGauge(value: voltage, status: status)
                // مسافة من فوق
                .padding(.top, 8)
        }
        // لون النصوص أبيض
        .foregroundStyle(.white)
        // حواف داخلية
        .padding(20)
        // خلفية متدرجة من لون الحالة إلى لون الكرت
        .background(
            LinearGradient(
                colors: [status.color, .batCard],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        // زوايا دائرية
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - صندوق التحذير
    // صار دالة تستقبل النص، لأن النص يختلف حسب الحالة
    private func warningBox(_ text: String) -> some View {
        // أيقونة + نص
        HStack(spacing: 12) {
            // أيقونة تحذير
            Image(systemName: "exclamationmark.octagon")
                // حجم الأيقونة
                .font(.title2)
            // النص اللي جانا
            Text(text)
                // خط عادي
                .font(.subheadline)
            // يملأ باقي العرض
            Spacer()
        }
        // لون أحمر فاتح
        .foregroundStyle(Color.batWarningText)
        // حواف داخلية
        .padding(.horizontal, 16)
        // ارتفاع أقل شي 84 (ويكبر لو النص طويل)
        .frame(minHeight: 84)
        // الخلفية
        .background(
            RoundedRectangle(cornerRadius: 20)
                // لون الحالة شفاف
                .fill(status.color.opacity(0.6))
                // إطار خفيف
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.batWarningText.opacity(0.25), lineWidth: 1)
                )
        )
        // يتلاشى ويصغر لما يطلع أو يختفي
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - زر "أقرب ورشة"
    // يفتح قوقل ماب ويبحث عن ورش قريبة
    // تطبيقنا ما يحتاج نت، لكن البحث داخل الخريطة يحتاج داتا (إلا لو الخرائط محمّلة أوفلاين)
    private var workshopButton: some View {
        Button {
            // كلمة البحث، ونحوّلها لصيغة تنفع في الرابط (عشان الحروف العربية)
            let query = "ورشة سيارات".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            // رابط تطبيق قوقل ماب
            let googleMaps = URL(string: "comgooglemaps://?q=\(query)")!
            // رابط خرائط أبل (احتياط لو قوقل ماب مو منزّل)
            let appleMaps = URL(string: "maps://?q=\(query)")!
            // نحاول نفتح قوقل ماب، ولو ما انفتح (opened = false) نفتح خرائط أبل
            openURL(googleMaps) { opened in
                if !opened { openURL(appleMaps) }
            }
        } label: {
            // أيقونة خريطة + نص
            HStack(spacing: 12) {
                // أيقونة الخريطة
                Image(systemName: "map")
                // نص الزر
                Text("أقرب ورشة")
                    // خط عريض
                    .fontWeight(.semibold)
            }
            // لون أبيض
            .foregroundStyle(.white)
            // كامل العرض
            .frame(maxWidth: .infinity)
            // ارتفاع الزر
            .frame(height: 46)
            // خلفية بلون الحالة
            .background(Capsule().fill(status.color))
            // ظل خفيف بلون الحالة
            .shadow(color: status.color.opacity(0.5), radius: 10, y: 4)
        }
    }

    // MARK: - زر "ذكّرني"
    private var reminderButton: some View {
        // عمود: الزر، وتحته وقت التذكير لو فيه تذكير
        VStack(spacing: 10) {
            // Menu: زر لما تضغطه تطلع قائمة خيارات
            Menu {
                // كل خيار يحسب وقت ويرسله لـ scheduleReminder
                // 60 × 60 = ساعة بالثواني
                Button("بعد ساعة") { scheduleReminder(at: .now.addingTimeInterval(60 * 60)) }
                // بكرة الساعة 9 الصبح (محسوبة تحت)
                Button("غدًا الساعة 9 صباحًا") { scheduleReminder(at: tomorrowMorning) }
                // 3 × 24 × 60 × 60 = 3 أيام بالثواني
                Button("بعد 3 أيام") { scheduleReminder(at: .now.addingTimeInterval(3 * 24 * 60 * 60)) }
            } label: {
                // شكل الزر: أيقونة جرس + نص
                HStack(spacing: 12) {
                    // جرس عادي لو ما فيه تذكير، وجرس مليان لو فيه
                    Image(systemName: reminderDate == nil ? "bell" : "bell.fill")
                    // النص حسب وجود تذكير
                    Text(reminderDate == nil ? "ذكّرني" : "تغيير وقت التذكير")
                        // خط عريض
                        .fontWeight(.semibold)
                }
                // لون أبيض
                .foregroundStyle(.white)
                // كامل العرض
                .frame(maxWidth: .infinity)
                // ارتفاع الزر
                .frame(height: 46)
                // زر ثانوي: إطار بلون الحالة بدل خلفية مليانة (عشان ما يشبه زر الورشة)
                .overlay(Capsule().stroke(status.color, lineWidth: 1.5))
            }

            // if let: لو فيه تذكير محفوظ، نعرض وقته وزر الإلغاء
            if let date = reminderDate {
                // وقت التذكير (formatted يكتب التاريخ والساعة بلغة الجوال)
                Text("سنذكّرك: \(date.formatted(date: .abbreviated, time: .shortened))")
                    // خط صغير
                    .font(.footnote)
                    // لون باهت
                    .foregroundStyle(.white.opacity(0.8))
                // زر إلغاء التذكير
                Button("إلغاء التذكير") {
                    cancelReminder()
                }
                // خط صغير
                .font(.footnote)
                // لون أبهت
                .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - حسابات التذكير
    // وقت التذكير المحفوظ كتاريخ، أو nil لو ما فيه تذكير أو وقته فات
    private var reminderDate: Date? {
        // نحوّل الرقم المحفوظ لتاريخ
        let date = Date(timeIntervalSince1970: reminderTime)
        // لو التاريخ بالمستقبل نرجعه، غير كذا nil
        return date > .now ? date : nil
    }

    // بكرة الساعة 9:00 الصبح
    private var tomorrowMorning: Date {
        // Calendar.current هو تقويم الجوال
        let calendar = Calendar.current
        // نضيف يوم على اليوم (! يعني متأكدين إن النتيجة مو nil)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now)!
        // نخلي الساعة 9:00:00 من نفس اليوم
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
    }

    // MARK: - جدولة التذكير
    private func scheduleReminder(at date: Date) {
        // نحفظ وقت التذكير عشان نعرضه تحت الزر
        reminderTime = date.timeIntervalSince1970

        // محتوى الإشعار
        let content = UNMutableNotificationContent()
        // العنوان: نفس عنوان الحالة (مثل "البطارية لا تُشحن")
        content.title = status.title
        // النص: رسالة التذكير الخاصة بالحالة
        content.body = status.reminderText
        // صوت الإشعار الافتراضي
        content.sound = .default

        // نفصّل التاريخ لسنة وشهر ويوم وساعة ودقيقة
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        // متى يطلع الإشعار: لما يوصل الوقت لهالتاريخ، مرة وحدة
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        // الطلب، وله اسم ثابت عشان نقدر نلغيه أو نبدله
        let request = UNNotificationRequest(identifier: "batteryReminder", content: content, trigger: trigger)

        // Task: نشغّل كود async (ينتظر رد المستخدم بدون ما يوقف الشاشة)
        Task {
            // مركز الإشعارات في الجوال
            let center = UNUserNotificationCenter.current()
            // نطلب الإذن (أول مرة بس يطلع للمستخدم سؤال)، و try? يعني لو صار خطأ نعتبره رفض
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            // لو رفض نطلع
            guard granted else { return }
            // نشيل أي تذكير قديم لنفس الصفحة عشان ما يتكرر
            center.removePendingNotificationRequests(withIdentifiers: ["batteryReminder"])
            // نضيف التذكير الجديد
            try? await center.add(request)
        }
    }

    // MARK: - إلغاء التذكير
    private func cancelReminder() {
        // صفر = ما فيه تذكير
        reminderTime = 0
        // نلغي الإشعار المجدول باسمه
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["batteryReminder"])
    }

}

// MARK: - مؤشر الجهد
// نفس فكرة TemperatureGauge بس بأرقام البطارية
struct BatteryGauge: View {
    // الجهد الحالي
    let value: Double
    // الحالة الحالية
    let status: BatteryStatus

    // حدود الأقسام بالفولت
    private let minValue: Double = 12.0   // بداية الشريط
    private let lowEnd: Double = 13.2     // نهاية المنخفض = بداية الطبيعي
    private let normalEnd: Double = 14.8  // نهاية الطبيعي = بداية المرتفع
    private let maxValue: Double = 16.0   // نهاية الشريط

    // عرض كل قسم كنسبة من الشريط
    private let lowWidth: Double = 0.35     // المنخفض 35%
    private let normalWidth: Double = 0.40  // الطبيعي 40%
    // المرتفع ياخذ الباقي (25%)
    private var highWidth: Double { 1 - lowWidth - normalWidth }

    // مكان الدائرة من 0 إلى 1
    private var progress: Double {
        // نتأكد إن الرقم داخل حدود الشريط
        let v = min(max(value, minValue), maxValue)
        // نشوف الرقم في أي قسم
        switch v {
        // في المنخفض
        case ..<lowEnd:
            return (v - minValue) / (lowEnd - minValue) * lowWidth
        // في الطبيعي
        case ..<normalEnd:
            return lowWidth + (v - lowEnd) / (normalEnd - lowEnd) * normalWidth
        // في المرتفع
        default:
            return lowWidth + normalWidth + (v - normalEnd) / (maxValue - normalEnd) * highWidth
        }
    }

    // لون القسم: أبيض لو هو الحالي، رمادي لو لا
    private func segmentColor(for segment: BatteryStatus) -> Color {
        segment == status ? .white : .gray.opacity(0.4)
    }

    var body: some View {
        // الشريط فوق والعناوين تحت
        VStack(spacing: 8) {
            // نقيس العرض المتاح
            GeometryReader { geo in
                // الدائرة فوق الشريط
                ZStack(alignment: .leading) {
                    // 3 أقسام جنب بعض
                    HStack(spacing: 3) {
                        // المنخفض
                        Capsule().fill(segmentColor(for: .low))
                            .frame(width: geo.size.width * lowWidth)
                        // الطبيعي
                        Capsule().fill(segmentColor(for: .normal))
                            .frame(width: geo.size.width * normalWidth)
                        // المرتفع (الباقي)
                        Capsule().fill(segmentColor(for: .high))
                    }
                    // ارتفاع الشريط
                    .frame(height: 6)

                    // الدائرة
                    Circle()
                        // لونها حسب الحالة
                        .fill(status.color)
                        // إطار أبيض
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        // مقاسها
                        .frame(width: 18, height: 18)
                        // مكانها حسب النسبة
                        .offset(x: progress * (geo.size.width - 18))
                }
                // بالنص عموديًا
                .frame(maxHeight: .infinity)
            }
            // ارتفاع المساحة
            .frame(height: 20)

            // العناوين تحت الشريط
            HStack {
                // يمين
                Text("منخفض")
                Spacer()
                // الوسط
                Text("الطبيعي 13.2–14.8")
                Spacer()
                // يسار
                Text("مرتفع")
            }
            // خط صغير جدًا
            .font(.caption2)
            // لون رمادي
            .foregroundStyle(.white.opacity(0.7))
        }
        // الدائرة تتزحلق بنعومة
        .animation(.spring(duration: 0.4), value: value)
    }
}

// MARK: - صف قابل للفتح والإغلاق
// نسخة خاصة بصفحة البطارية (اسم مختلف عشان ما يتعارض مع ExpandableRow في صفحة الحرارة)
struct BatteryExpandableRow<Content: View>: View {
    // عنوان الصف
    let title: String
    // @Binding: المتغير موجود في الصفحة الأم واحنا نقرأه ونعدّله
    @Binding var isExpanded: Bool
    // المحتوى اللي يطلع لما ينفتح
    @ViewBuilder let content: () -> Content

    var body: some View {
        // العنوان فوق والمحتوى تحته
        VStack(alignment: .leading, spacing: 12) {
            // صف العنوان + السهم
            HStack {
                // العنوان
                Text(title)
                    // خط بوزن متوسط
                    .font(.body.weight(.medium))
                // يدفع السهم لليسار
                Spacer()
                // السهم
                Image(systemName: "chevron.left")
                    // خط عريض
                    .font(.body.weight(.semibold))
                    // يلف لتحت لما ينفتح (90 مو -90، لأن الصفحة من اليمين لليسار فالاتجاه ينعكس)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            // كامل الصف ينضغط
            .contentShape(Rectangle())
            // لما ينضغط
            .onTapGesture {
                // نقلب الحالة بحركة ناعمة
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }

            // لو مفتوح نعرض المحتوى
            if isExpanded {
                content()
                    // خط أصغر
                    .font(.subheadline)
                    // لون أفتح شوي
                    .foregroundStyle(.white.opacity(0.75))
                    // يطلع بشفافية من فوق
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        // نص أبيض
        .foregroundStyle(.white)
        // حواف داخلية
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        // كامل العرض
        .frame(maxWidth: .infinity)
        // الخلفية
        .background(
            RoundedRectangle(cornerRadius: 22)
                // بلون الكروت
                .fill(Color.batCard)
                // إطار خفيف
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - تجربة الشيت
// اسم مختلف عن SheetDemoView عشان ما يتعارض مع صفحة الحرارة لو كانت في نفس المشروع
struct BatterySheetDemoView: View {

    // هل الشيت مفتوح
    @State private var showSheet = false
    // الجهد (هنا في الصفحة الأم، ونرسله للشيت)
    @State private var voltage: Double = 14.3

    var body: some View {
        // السلايدر والزر
        VStack(spacing: 24) {
            // الرقم الحالي
            Text("الجهد: \(String(format: "%.1f", voltage)) فولت")
                // خط عريض
                .font(.title2.bold())

            // سلايدر من 12 إلى 16، ويتحرك 0.1 كل مرة
            Slider(value: $voltage, in: 12...16, step: 0.1)

            // زر يفتح الشيت
            Button("افتح صفحة البطارية") {
                // نفتح الشيت
                showSheet = true
            }
            // خط عريض
            .font(.title3.bold())
            // حواف داخلية
            .padding()
            // خلفية خضراء
            .background(Capsule().fill(Color.batNormal))

            // يدفع كل شي لفوق
            Spacer()
        }
        // حواف
        .padding(24)
        // نص أبيض
        .foregroundStyle(.white)
        // كامل الشاشة
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // خلفية سوداء
        .background(Color.black)
        // من اليمين لليسار
        .environment(\.layoutDirection, .rightToLeft)
        // الشيت
        .sheet(isPresented: $showSheet) {
            // نرسل الجهد للصفحة
            BatteryView(voltage: voltage)
                // نص الشاشة وكامل الشاشة
                .presentationDetents([.medium, .large])
                // السحب يحرّك الشيت أول
                .presentationContentInteraction(.resizes)
                // تقدر تلمس السلايدر والشيت على النص
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                // الشرطة الصغيرة فوق (المستخدم يسحبها لتحت عشان يسكّر)
                .presentationDragIndicator(.visible)
                // زوايا دائرية
                .presentationCornerRadius(40)
                // لون الخلفية
                .presentationBackground(Color.batBackground)
        }
    }
}

// MARK: - المعاينات
// أسماء مختلفة عن معاينات الحرارة عشان تفرق بينهم

// تجربة الشيت مع السلايدر
#Preview("بطارية - تجربة") {
    BatterySheetDemoView()
}

// الدينمو ما يشحن
#Preview("بطارية - منخفض") {
    BatteryView(voltage: 12.4)
}

// الحالة الطبيعية
#Preview("بطارية - طبيعي") {
    BatteryView(voltage: 14.3)
}

// شحن زائد
#Preview("بطارية - مرتفع") {
    BatteryView(voltage: 15.3)
}
