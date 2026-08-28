import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// MARK: - LiveActivitiesAppAttributes
// Redefinição local obrigatória — espelha exatamente o tipo do plugin live_activities.
// O plugin cria Activity<LiveActivitiesAppAttributes>; a extensão deve usar o mesmo tipo.

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {
        var appGroupId: String
    }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    // Chave prefixada com o UUID da atividade — padrão do plugin
    func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

// App Group compartilhado com o Runner
private let sharedDefault = UserDefaults(suiteName: "group.com.bldr.fitness")!

// MARK: - Design tokens

private let kGold    = Color(red: 0.878, green: 0.722, blue: 0.180)
private let kBg      = Color(red: 0.020, green: 0.020, blue: 0.020)
private let kMuted   = Color.white.opacity(0.45)

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct BLDRWorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let isRun = sharedDefault.string(
                forKey: context.attributes.prefixedKey("activityType")) == "run"
            return Group {
                if isRun {
                    BLDRRunLockScreenView(attr: context.attributes)
                } else {
                    BLDRLockScreenView(attr: context.attributes)
                }
            }
            .activityBackgroundTint(Color(red: 0.08, green: 0.08, blue: 0.08))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let isRun = sharedDefault.string(
                forKey: context.attributes.prefixedKey("activityType")) == "run"
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if isRun { EmptyView() }
                    else { BLDRExpandedLeading(attr: context.attributes) }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if isRun { EmptyView() }
                    else { BLDRExpandedTrailing(attr: context.attributes) }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if isRun { BLDRRunExpandedBottom(attr: context.attributes) }
                    else { BLDRExpandedBottom(attr: context.attributes) }
                }
            } compactLeading: {
                if isRun { BLDRRunCompactLeading(attr: context.attributes) }
                else { BLDRCompactLeading(attr: context.attributes) }
            } compactTrailing: {
                if isRun { BLDRRunCompactTrailing(attr: context.attributes) }
                else { BLDRCompactTrailing(attr: context.attributes) }
            } minimal: {
                if isRun { BLDRRunMinimal(attr: context.attributes) }
                else { BLDRMinimal(attr: context.attributes) }
            }
            .keylineTint(kGold)
        }
    }
}

// MARK: - Data helpers (lê do App Group UserDefaults)

private struct WorkoutState {
    let workoutName: String
    let exerciseName: String
    let exerciseSet: Int
    let exerciseTotalSets: Int
    let exerciseIndex: Int
    let exerciseTotalExercises: Int
    let workoutStartTimestamp: Double   // Unix ts — timer conta sozinho no device
    let isResting: Bool
    let restEndTimestamp: Double        // Unix ts — countdown conta sozinho no device
    let restTotalSeconds: Int
    let weightKg: Double
    let reps: Int

    init(attr: LiveActivitiesAppAttributes) {
        let d = sharedDefault
        workoutName            = d.string(forKey: attr.prefixedKey("workoutName")) ?? "Treino"
        exerciseName           = d.string(forKey: attr.prefixedKey("exerciseName")) ?? "—"
        exerciseSet            = d.integer(forKey: attr.prefixedKey("exerciseSet"))
        exerciseTotalSets      = max(1, d.integer(forKey: attr.prefixedKey("exerciseTotalSets")))
        exerciseIndex          = d.integer(forKey: attr.prefixedKey("exerciseIndex"))
        exerciseTotalExercises = max(1, d.integer(forKey: attr.prefixedKey("exerciseTotalExercises")))
        workoutStartTimestamp  = d.double(forKey: attr.prefixedKey("workoutStartTimestamp"))
        isResting              = d.bool(forKey: attr.prefixedKey("isResting"))
        restEndTimestamp       = d.double(forKey: attr.prefixedKey("restEndTimestamp"))
        restTotalSeconds       = max(1, d.integer(forKey: attr.prefixedKey("restTotalSeconds")))
        weightKg               = d.double(forKey: attr.prefixedKey("weightKg"))
        reps                   = d.integer(forKey: attr.prefixedKey("reps"))
    }

    var workoutStartDate: Date {
        workoutStartTimestamp > 0 ? Date(timeIntervalSince1970: workoutStartTimestamp) : .now
    }

    var restEndDate: Date {
        restEndTimestamp > 0 ? Date(timeIntervalSince1970: restEndTimestamp) : .now
    }

    var restSecondsRemaining: Int {
        max(0, Int(restEndDate.timeIntervalSince(.now)))
    }

    var restProgress: Double {
        let rem = Double(restSecondsRemaining)
        let total = Double(restTotalSeconds)
        return 1.0 - (rem / total)
    }
    var exerciseProgress: Double {
        Double(exerciseIndex) / Double(exerciseTotalExercises)
    }
    var weightStr: String {
        weightKg > 0 ? String(format: "%.1fkg", weightKg) : "Peso livre"
    }
}

// MARK: - Lock Screen view

@available(iOS 16.1, *)
private struct BLDRLockScreenView: View {
    let attr: LiveActivitiesAppAttributes

    var body: some View {
        let s = WorkoutState(attr: attr)
        VStack(alignment: .leading, spacing: 6) {
            // Linha superior: ícone + cronômetro
            HStack(alignment: .center) {
                Image(systemName: s.isResting ? "timer" : "dumbbell.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(kGold)
                Spacer()
                Group {
                    if s.isResting {
                        Text(timerInterval: .now...s.restEndDate, countsDown: true)
                    } else {
                        Text(s.workoutStartDate, style: .timer)
                    }
                }
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundColor(kGold)
                .monospacedDigit()
            }

            // Linha de exercício
            Text(s.isResting ? "Descansando" : s.exerciseName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(s.isResting ? kGold : .white)
                .lineLimit(1)

            // Detalhes
            Text("Série \(s.exerciseSet)/\(s.exerciseTotalSets) · \(s.weightStr) · \(s.reps) reps")
                .font(.system(size: 10))
                .foregroundColor(kMuted)

            // Botões de descanso
            if s.isResting {
                HStack(spacing: 8) {
                    if #available(iOS 17.0, *) {
                        Button(intent: BLDRAddRestTimeIntent()) {
                            Text("+15s")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(kBg)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(kGold).clipShape(Capsule())
                        }.buttonStyle(.plain)
                        Button(intent: BLDRSkipRestIntent()) {
                            Text("Pular")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.white.opacity(0.15)).clipShape(Capsule())
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [kGold, kGold.opacity(0.5), kGold.opacity(0.15), kGold.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Compact / Minimal views

@available(iOS 16.1, *)
private struct BLDRCompactLeading: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        let s = WorkoutState(attr: attr)
        if s.isResting {
            BLDRActivityRing(progress: s.restProgress, color: kGold, lineWidth: 3, size: 20)
        } else {
            Image(systemName: "dumbbell.fill")
                .foregroundColor(kGold)
                .font(.system(size: 12))
        }
    }
}

@available(iOS 16.1, *)
private struct BLDRCompactTrailing: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        let s = WorkoutState(attr: attr)
        if s.isResting {
            Text(timerInterval: .now...s.restEndDate, countsDown: true)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(kGold)
                .monospacedDigit()
                .frame(width: 38)
        } else {
            Text(s.workoutStartDate, style: .timer)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(kGold)
                .monospacedDigit()
                .frame(width: 38)
        }
    }
}

@available(iOS 16.1, *)
private struct BLDRMinimal: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        let s = WorkoutState(attr: attr)
        Image(systemName: s.isResting ? "timer" : "dumbbell.fill")
            .font(.system(size: 12)).foregroundColor(kGold)
    }
}

// MARK: - Expanded views

// Leading e Trailing ficam mínimos — o conteúdo principal vai no Bottom
@available(iOS 16.1, *)
private struct BLDRExpandedLeading: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View { EmptyView() }
}

@available(iOS 16.1, *)
private struct BLDRExpandedTrailing: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View { EmptyView() }
}

@available(iOS 16.1, *)
private struct BLDRExpandedBottom: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        let s = WorkoutState(attr: attr)
        if s.isResting {
            // Estado de descanso: ring + botões
            HStack(spacing: 14) {
                ZStack {
                    BLDRActivityRing(progress: s.restProgress, color: kGold, lineWidth: 5, size: 54)
                    VStack(spacing: 1) {
                        Text(timerInterval: .now...s.restEndDate, countsDown: true)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(kGold)
                            .monospacedDigit()
                        Text("desc").font(.system(size: 8)).foregroundColor(kMuted)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("DESCANSANDO").font(.system(size: 9, weight: .black)).foregroundColor(kGold).kerning(0.8)
                    Text("Próx: \(s.exerciseName)").font(.system(size: 11, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text("Série \(s.exerciseSet + 1)/\(s.exerciseTotalSets) · \(s.weightStr)").font(.system(size: 10)).foregroundColor(kMuted)
                    if #available(iOS 17.0, *) {
                        HStack(spacing: 8) {
                            Button(intent: BLDRAddRestTimeIntent()) {
                                Text("+15s").font(.system(size: 11, weight: .bold)).foregroundColor(kBg)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(kGold).clipShape(Capsule())
                            }.buttonStyle(.plain)
                            Button(intent: BLDRSkipRestIntent()) {
                                Text("Pular").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.white.opacity(0.15)).clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        } else {
            // Estado de treino: layout de 3 colunas conforme mockup
            HStack(spacing: 0) {

                // Coluna esquerda: ícone + Série / Carga / Reps
                VStack(spacing: 7) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 17))
                        .foregroundColor(kGold)
                        .frame(width: 36, height: 36)
                        .background(kGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    BLDRStat(label: "Série", value: "\(s.exerciseSet)/\(s.exerciseTotalSets)")
                    BLDRStat(label: "Carga", value: s.weightStr)
                    BLDRStat(label: "Reps", value: "\(s.reps)")
                }
                .frame(width: 62)

                // Divisória vertical
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 1)
                    .padding(.vertical, 4)

                // Coluna central: exercício + progresso
                VStack(alignment: .leading, spacing: 5) {
                    Text("Exercício \(s.exerciseIndex + 1)/\(s.exerciseTotalExercises)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(0.5)
                        .textCase(.uppercase)
                    Text(s.exerciseName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(3)
                    Spacer(minLength: 0)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 2)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [kGold.opacity(0.5), kGold],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * s.exerciseProgress), height: 2)
                        }
                    }.frame(height: 2)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)

                // Divisória vertical
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 1)
                    .padding(.vertical, 4)

                // Coluna direita: cronômetro
                VStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                    Text(s.workoutStartDate, style: .timer)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(kGold)
                        .monospacedDigit()
                    Text("tempo")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: 62)
            }
        }
    }
}

// Stat label+value usado na coluna esquerda do expanded
private struct BLDRStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Ring helper

private struct BLDRActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: lineWidth)
            Circle().trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
