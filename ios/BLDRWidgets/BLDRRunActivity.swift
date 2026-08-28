import ActivityKit
import SwiftUI

// MARK: - Design tokens (fileprivate — não conflita com BLDRWorkoutActivity.swift)
private let kRunGold  = Color(red: 0.878, green: 0.722, blue: 0.188)
private let kRunMuted = Color.white.opacity(0.45)

// App Group — mesmo suiteName do BLDRWorkoutActivity
private let runUD = UserDefaults(suiteName: "group.com.bldr.fitness")!

// MARK: - RunState: lê dados de corrida do UserDefaults compartilhado

@available(iOS 16.1, *)
struct RunState {
    let startTimestamp: Double
    let distanceM: Double
    let paceSec: Double
    let hr: Double
    let isActive: Bool

    init(attr: LiveActivitiesAppAttributes) {
        let d = runUD
        startTimestamp = d.double(forKey: attr.prefixedKey("startTimestamp"))
        distanceM      = d.double(forKey: attr.prefixedKey("distanceM"))
        paceSec        = d.double(forKey: attr.prefixedKey("paceSec"))
        hr             = d.double(forKey: attr.prefixedKey("hr"))
        isActive       = d.bool(forKey:   attr.prefixedKey("isActive"))
    }

    /// Data de início usada pelo Text(.timer) — auto-avança no iOS sem updates do Dart
    var startDate: Date {
        startTimestamp > 0 ? Date(timeIntervalSince1970: startTimestamp) : .now
    }

    var distanceStr: String {
        let km = distanceM / 1000
        return km >= 1 ? String(format: "%.2f km", km)
                       : String(format: "%.0f m", distanceM)
    }

    var paceStr: String {
        guard paceSec > 0 else { return "--:--" }
        let min = Int(paceSec) / 60
        let sec = Int(paceSec) % 60
        return String(format: "%d:%02d", min, sec)
    }

    var hrStr: String { hr > 0 ? "\(Int(hr)) bpm" : "--" }
}

// MARK: - Lock Screen

@available(iOS 16.1, *)
struct BLDRRunLockScreenView: View {
    let attr: LiveActivitiesAppAttributes

    var body: some View {
        let s = RunState(attr: attr)
        VStack(alignment: .leading, spacing: 8) {
            // Linha 1: ícone + "BLDR Run" + timer em badge
            HStack(alignment: .center) {
                Image(systemName: "figure.run")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(kRunGold)
                Text("BLDR Run")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if s.isActive {
                    Text(s.startDate, style: .timer)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(kRunGold)
                        .monospacedDigit()
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(kRunGold.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("PAUSADO")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(kRunGold)
                        .kerning(0.8)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(kRunGold.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Linha 2: distância · pace · FC
            HStack(spacing: 8) {
                Label(s.distanceStr, systemImage: "location.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
                Text("·").foregroundColor(kRunMuted)
                Label("\(s.paceStr)/km", systemImage: "speedometer")
                    .font(.system(size: 11))
                    .foregroundColor(kRunMuted)
                if s.hr > 0 {
                    Text("·").foregroundColor(kRunMuted)
                    Label(s.hrStr, systemImage: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(kRunMuted)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [kRunGold, kRunGold.opacity(0.5),
                                 kRunGold.opacity(0.15), kRunGold.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Compact (Dynamic Island fechada)

@available(iOS 16.1, *)
struct BLDRRunCompactLeading: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        Image(systemName: "figure.run")
            .foregroundColor(kRunGold)
            .font(.system(size: 12))
    }
}

@available(iOS 16.1, *)
struct BLDRRunCompactTrailing: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        let s = RunState(attr: attr)
        if s.isActive {
            Text(s.startDate, style: .timer)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(kRunGold)
                .monospacedDigit()
                .frame(width: 40)
        } else {
            Text("||")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(kRunGold)
        }
    }
}

// MARK: - Minimal (duas LiveActivities simultâneas)

@available(iOS 16.1, *)
struct BLDRRunMinimal: View {
    let attr: LiveActivitiesAppAttributes
    var body: some View {
        Image(systemName: "figure.run")
            .font(.system(size: 12))
            .foregroundColor(kRunGold)
    }
}

// MARK: - Expanded bottom — layout de 3 colunas

@available(iOS 16.1, *)
struct BLDRRunExpandedBottom: View {
    let attr: LiveActivitiesAppAttributes

    var body: some View {
        let s = RunState(attr: attr)

        HStack(spacing: 0) {
            // Coluna esquerda: figure.run + distância
            VStack(spacing: 5) {
                Image(systemName: "figure.run")
                    .font(.system(size: 18))
                    .foregroundColor(kRunGold)
                    .frame(width: 36, height: 36)
                    .background(kRunGold.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(s.distanceStr)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                Text("dist.")
                    .font(.system(size: 8))
                    .foregroundColor(kRunMuted)
            }
            .frame(width: 62)

            // Divisória
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Coluna central: status + cronômetro
            VStack(spacing: 4) {
                Text(s.isActive ? "EM CORRIDA" : "PAUSADO")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(kRunGold)
                    .kerning(0.8)
                if s.isActive {
                    Text(s.startDate, style: .timer)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(kRunGold)
                        .monospacedDigit()
                } else {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(kRunGold.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)

            // Divisória
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Coluna direita: FC (se disponível) ou pace
            VStack(spacing: 5) {
                if s.hr > 0 {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(s.hrStr)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Text("bpm")
                        .font(.system(size: 8))
                        .foregroundColor(kRunMuted)
                } else {
                    Image(systemName: "speedometer")
                        .font(.system(size: 16))
                        .foregroundColor(kRunGold)
                        .frame(width: 36, height: 36)
                        .background(kRunGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(s.paceStr)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Text("pace")
                        .font(.system(size: 8))
                        .foregroundColor(kRunMuted)
                }
            }
            .frame(width: 62)
        }
    }
}
