import WidgetKit
import SwiftUI

// MARK: - Design Tokens

private let kGold     = Color(red: 0.878, green: 0.722, blue: 0.180) // #E0B830
private let kBg       = Color(red: 0.020, green: 0.020, blue: 0.020) // #050505
private let kSurface  = Color.white.opacity(0.05)
private let kBorder   = Color.white.opacity(0.08)
private let kMuted    = Color.white.opacity(0.45)
private let kGoldGlow = Color(red: 0.788, green: 0.635, blue: 0.153).opacity(0.20)

private let kGroupId  = "group.com.bldr.fitness"

// MARK: - Shared data model

struct BLDRWidgetData {
    let streakDays: Int
    let weekDays: [Bool]       // 7 elementos Mon–Sun
    let caloriesConsumed: Int
    let caloriesGoal: Int
    let macroProtein: Int
    let macroProteinGoal: Int
    let macroCarbs: Int
    let macroCarbsGoal: Int
    let macroFat: Int
    let macroFatGoal: Int
    let workoutName: String
    let workoutExercises: Int
    let workoutDuration: Int   // minutos
    let workoutTemplateId: String
    let xpToday: Int

    static func load() -> BLDRWidgetData {
        let d = UserDefaults(suiteName: kGroupId)
        let weekJson = d?.string(forKey: "bldr_streak_week") ?? "[]"
        var weekDays: [Bool] = Array(repeating: false, count: 7)
        if let data = weekJson.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Bool].self, from: data),
           decoded.count == 7 {
            weekDays = decoded
        }
        return BLDRWidgetData(
            streakDays:        d?.integer(forKey: "bldr_streak_days") ?? 0,
            weekDays:          weekDays,
            caloriesConsumed:  d?.integer(forKey: "bldr_calories_consumed") ?? 0,
            caloriesGoal:      max(1, d?.integer(forKey: "bldr_calories_goal") ?? 2000),
            macroProtein:      d?.integer(forKey: "bldr_macro_protein") ?? 0,
            macroProteinGoal:  max(1, d?.integer(forKey: "bldr_macro_protein_goal") ?? 120),
            macroCarbs:        d?.integer(forKey: "bldr_macro_carbs") ?? 0,
            macroCarbsGoal:    max(1, d?.integer(forKey: "bldr_macro_carbs_goal") ?? 250),
            macroFat:          d?.integer(forKey: "bldr_macro_fat") ?? 0,
            macroFatGoal:      max(1, d?.integer(forKey: "bldr_macro_fat_goal") ?? 67),
            workoutName:       d?.string(forKey: "bldr_workout_name") ?? "Sem treino hoje",
            workoutExercises:  d?.integer(forKey: "bldr_workout_exercises") ?? 0,
            workoutDuration:   d?.integer(forKey: "bldr_workout_duration") ?? 0,
            workoutTemplateId: d?.string(forKey: "bldr_workout_template_id") ?? "",
            xpToday:           d?.integer(forKey: "bldr_xp_today") ?? 0
        )
    }
}

// MARK: - Shared Timeline Provider

struct BLDREntry: TimelineEntry {
    let date: Date
    let data: BLDRWidgetData
}

struct BLDRProvider: TimelineProvider {
    func placeholder(in context: Context) -> BLDREntry {
        BLDREntry(date: .now, data: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (BLDREntry) -> Void) {
        completion(BLDREntry(date: .now, data: context.isPreview ? .placeholder : .load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BLDREntry>) -> Void) {
        let entry = BLDREntry(date: .now, data: .load())
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

extension BLDRWidgetData {
    static let placeholder = BLDRWidgetData(
        streakDays: 5, weekDays: [true,true,false,true,true,false,false],
        caloriesConsumed: 1450, caloriesGoal: 2000,
        macroProtein: 105, macroProteinGoal: 150,
        macroCarbs: 180, macroCarbsGoal: 250,
        macroFat: 42, macroFatGoal: 67,
        workoutName: "Peito & Tríceps",
        workoutExercises: 8, workoutDuration: 55,
        workoutTemplateId: "", xpToday: 320
    )
}

// MARK: - Shared views

struct BLDRProgressRing: View {
    let progress: Double    // 0…1
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct BLDRWeekDots: View {
    let days: [Bool]
    let size: CGFloat

    private let labels = ["S","T","Q","Q","S","S","D"]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: size * 0.25)
                        .fill(days[i] ? kGold : Color.white.opacity(0.10))
                        .frame(width: size, height: size)
                        .overlay(
                            days[i] ? Image(systemName: "dumbbell.fill")
                                .font(.system(size: size * 0.45, weight: .bold))
                                .foregroundColor(kBg) : nil
                        )
                    Text(labels[i])
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(kMuted)
                }
            }
        }
    }
}

struct BLDRMacroBar: View {
    let label: String
    let value: Int
    let goal: Int
    let color: Color

    var progress: Double { Double(value) / Double(max(1, goal)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(kMuted)
                Spacer()
                Text("\(value)g")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 4)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(1, progress), height: 4)
                }
            }.frame(height: 4)
        }
    }
}

struct BLDRLogoLabel: View {
    var body: some View {
        Text("BLDR")
            .font(.system(size: 9, weight: .black))
            .foregroundColor(kGold)
            .kerning(1.5)
    }
}

// MARK: - BLDRStreakWidget (Small)

struct BLDRStreakView: View {
    let data: BLDRWidgetData

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                BLDRLogoLabel()
                Spacer()
                Text("🔥")
                    .font(.system(size: 12))
            }
            Spacer()
            ZStack {
                BLDRProgressRing(
                    progress: Double(data.weekDays.filter { $0 }.count) / 7.0,
                    color: kGold,
                    lineWidth: 8
                )
                VStack(spacing: 0) {
                    Text("\(data.streakDays)")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                    Text("dias")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(kMuted)
                }
            }
            .frame(width: 72, height: 72)
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(data.weekDays[i] ? kGold : Color.white.opacity(0.12))
                        .frame(height: 4)
                }
            }
        }
        .padding(14)
    }
}

struct BLDRStreakWidget: Widget {
    let kind = "BLDRStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BLDRProvider()) { entry in
            BLDRStreakView(data: entry.data)
                .containerBackground(for: .widget) {
                    ZStack {
                        kBg
                        RadialGradient(
                            gradient: Gradient(colors: [kGoldGlow, .clear]),
                            center: .top, startRadius: 0, endRadius: 100
                        )
                    }
                }
        }
        .configurationDisplayName("Sequência BLDR")
        .description("Seu streak de treinos e progresso semanal.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryInline,
        ])
    }
}

// MARK: - BLDRCaloriasWidget (Small)

struct BLDRCaloriasView: View {
    let data: BLDRWidgetData

    var calPct: Double { Double(data.caloriesConsumed) / Double(data.caloriesGoal) }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                BLDRLogoLabel()
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundColor(kGold)
            }
            Spacer()
            ZStack {
                BLDRProgressRing(progress: calPct, color: kGold, lineWidth: 8)
                VStack(spacing: 0) {
                    Text("\(data.caloriesConsumed)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                    Text("kcal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(kMuted)
                }
            }
            .frame(width: 72, height: 72)
            Spacer()
            Text("de \(data.caloriesGoal) kcal")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(kMuted)
        }
        .padding(14)
    }
}

struct BLDRCaloriasWidget: Widget {
    let kind = "BLDRCaloriasWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BLDRProvider()) { entry in
            BLDRCaloriasView(data: entry.data)
                .containerBackground(for: .widget) {
                    ZStack {
                        kBg
                        RadialGradient(
                            gradient: Gradient(colors: [kGoldGlow, .clear]),
                            center: .top, startRadius: 0, endRadius: 100
                        )
                    }
                }
        }
        .configurationDisplayName("Calorias BLDR")
        .description("Consumo de calorias do dia versus sua meta.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

// MARK: - BLDRResumoWidget (Medium)

struct BLDRResumoWidget: Widget {
    let kind = "BLDRResumoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BLDRProvider()) { entry in
            BLDRResumoView(data: entry.data)
                .containerBackground(kBg, for: .widget)
        }
        .configurationDisplayName("Resumo do Dia BLDR")
        .description("Treino de hoje, macros e progresso semanal.")
        .supportedFamilies([.systemMedium, .accessoryRectangular])
    }
}

struct BLDRResumoView: View {
    let data: BLDRWidgetData

    var body: some View {
        HStack(spacing: 0) {
            // Coluna esquerda — treino
            VStack(alignment: .leading, spacing: 6) {
                BLDRLogoLabel()
                Text("Treino de hoje")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(kMuted)
                Text(data.workoutName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                if data.workoutExercises > 0 {
                    Text("\(data.workoutExercises) ex · ~\(data.workoutDuration) min")
                        .font(.system(size: 9))
                        .foregroundColor(kMuted)
                }
                Spacer()
                BLDRWeekDots(days: data.weekDays, size: 12)
                Spacer()
                HStack(spacing: 8) {
                    Label("\(data.streakDays)d", systemImage: "flame.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(kGold)
                    Label("\(data.caloriesConsumed) kcal", systemImage: "fork.knife")
                        .font(.system(size: 9))
                        .foregroundColor(kMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divisória
            Rectangle()
                .fill(kBorder)
                .frame(width: 1)
                .padding(.vertical, 4)

            // Coluna direita — macros + botão
            VStack(alignment: .leading, spacing: 6) {
                BLDRMacroBar(
                    label: "Proteína",
                    value: data.macroProtein,
                    goal: data.macroProteinGoal,
                    color: Color(red: 0.36, green: 0.72, blue: 1.0)
                )
                BLDRMacroBar(
                    label: "Carbs",
                    value: data.macroCarbs,
                    goal: data.macroCarbsGoal,
                    color: kGold
                )
                BLDRMacroBar(
                    label: "Gordura",
                    value: data.macroFat,
                    goal: data.macroFatGoal,
                    color: Color(red: 1.0, green: 0.55, blue: 0.20)
                )
                Spacer()
                if !data.workoutTemplateId.isEmpty,
                   let url = URL(string: "bldr://workout/start/\(data.workoutTemplateId)") {
                    Link(destination: url) {
                        Text("▶ Iniciar")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(kBg)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(kGold)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
        }
        .padding(14)
    }
}

// MARK: - BLDRDashboardWidget (Large)

struct BLDRDashboardWidget: Widget {
    let kind = "BLDRDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BLDRProvider()) { entry in
            BLDRDashboardView(data: entry.data)
                .containerBackground(for: .widget) {
                    ZStack {
                        kBg
                        RadialGradient(
                            gradient: Gradient(colors: [kGoldGlow, .clear]),
                            center: .top, startRadius: 0, endRadius: 180
                        )
                    }
                }
        }
        .configurationDisplayName("Dashboard BLDR")
        .description("Treino, streak, calorias e semana em um só lugar.")
        .supportedFamilies([.systemLarge])
    }
}

struct BLDRDashboardView: View {
    let data: BLDRWidgetData

    private var calPct: Double { Double(data.caloriesConsumed) / Double(data.caloriesGoal) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    BLDRLogoLabel()
                    Spacer()
                    Label("\(data.streakDays) dias", systemImage: "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(kGold)
                }

                // Hero treino
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(kSurface)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(kBorder, lineWidth: 1))
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Treino de hoje")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(kMuted)
                            Text(data.workoutName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            if data.workoutExercises > 0 {
                                Text("\(data.workoutExercises) exercícios · ~\(data.workoutDuration) min")
                                    .font(.system(size: 10))
                                    .foregroundColor(kMuted)
                            }
                        }
                        Spacer()
                        if !data.workoutTemplateId.isEmpty,
                           let url = URL(string: "bldr://workout/start/\(data.workoutTemplateId)") {
                            Link(destination: url) {
                                Text("Iniciar")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(kBg)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(kGold)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(12)
                }
                .frame(height: 72)

                // Stats grid
                HStack(spacing: 10) {
                    // Streak
                    BLDRStatCard(
                        value: "\(data.streakDays)",
                        label: "streak",
                        icon: "flame.fill",
                        color: kGold
                    )
                    // Calorias com barra
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(kSurface)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(kBorder, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 10))
                                    .foregroundColor(kGold)
                                Text("\(data.caloriesConsumed)")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.white)
                            }
                            Text("kcal · \(Int(calPct * 100))%")
                                .font(.system(size: 8))
                                .foregroundColor(kMuted)
                            BLDRProgressRing(progress: calPct, color: kGold, lineWidth: 4)
                                .frame(width: 28, height: 28)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // XP
                    BLDRStatCard(
                        value: "\(data.xpToday)",
                        label: "XP hoje",
                        icon: "bolt.fill",
                        color: Color(red: 0.36, green: 0.72, blue: 1.0)
                    )
                }
                .frame(height: 72)

                // Semana
                VStack(alignment: .leading, spacing: 6) {
                    Text("Esta semana")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(kMuted)
                    BLDRWeekDots(days: data.weekDays, size: 20)
                }

                // Macros
                VStack(spacing: 6) {
                    BLDRMacroBar(
                        label: "Proteína",
                        value: data.macroProtein,
                        goal: data.macroProteinGoal,
                        color: Color(red: 0.36, green: 0.72, blue: 1.0)
                    )
                    BLDRMacroBar(
                        label: "Carbs",
                        value: data.macroCarbs,
                        goal: data.macroCarbsGoal,
                        color: kGold
                    )
                    BLDRMacroBar(
                        label: "Gordura",
                        value: data.macroFat,
                        goal: data.macroFatGoal,
                        color: Color(red: 1.0, green: 0.55, blue: 0.20)
                    )
                }
        }
        .padding(16)
    }
}

struct BLDRStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(kSurface)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(kBorder, lineWidth: 1))
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(kMuted)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Lock Screen Widgets

// accessoryInline — acima do relógio
struct BLDRInlineView: View {
    let data: BLDRWidgetData
    var body: some View {
        Text("🔥 \(data.streakDays)d · \(data.caloriesConsumed)/\(data.caloriesGoal) kcal")
    }
}

// accessoryCircular — streak
struct BLDRCircularStreakView: View {
    let data: BLDRWidgetData
    var weekPct: Double { Double(data.weekDays.filter { $0 }.count) / 7.0 }
    var body: some View {
        ZStack {
            BLDRProgressRing(progress: weekPct, color: .white, lineWidth: 4)
            VStack(spacing: 0) {
                Text("\(data.streakDays)")
                    .font(.system(size: 14, weight: .black))
                Text("🔥")
                    .font(.system(size: 8))
            }
        }
    }
}

// accessoryCircular — calorias
struct BLDRCircularCaloriasView: View {
    let data: BLDRWidgetData
    var pct: Double { Double(data.caloriesConsumed) / Double(data.caloriesGoal) }
    var body: some View {
        ZStack {
            BLDRProgressRing(progress: pct, color: .white, lineWidth: 4)
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
        }
    }
}

// accessoryRectangular — treino do dia
struct BLDRRectangularView: View {
    let data: BLDRWidgetData
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text(data.workoutName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                if data.workoutExercises > 0 {
                    Text("\(data.workoutExercises) ex · ~\(data.workoutDuration) min")
                        .font(.system(size: 9))
                        .opacity(0.7)
                }
                if !data.workoutTemplateId.isEmpty {
                    Text("Iniciar →")
                        .font(.system(size: 9, weight: .bold))
                        .opacity(0.85)
                }
            }
        }
    }
}

// Widgets adicionais para Lock Screen usando BLDRStreakWidget e BLDRCaloriasWidget
// (já declarados acima com .accessoryCircular e .accessoryInline como famílias suportadas)
// accessoryRectangular precisa de um widget próprio:
struct BLDRRectangularWidget: Widget {
    let kind = "BLDRRectangularWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BLDRProvider()) { entry in
            BLDRRectangularWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Treino — Tela de Bloqueio")
        .description("Treino do dia na tela de bloqueio.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct BLDRRectangularWidgetView: View {
    let entry: BLDREntry

    var body: some View {
        if !entry.data.workoutTemplateId.isEmpty,
           let url = URL(string: "bldr://workout/start/\(entry.data.workoutTemplateId)") {
            Link(destination: url) { BLDRRectangularView(data: entry.data) }
        } else {
            BLDRRectangularView(data: entry.data)
        }
    }
}
