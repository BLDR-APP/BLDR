import SwiftUI
import WatchKit

private let kGold = Color(red: 0.831, green: 0.686, blue: 0.216)

// MARK: - Root

struct RunView: View {
    @StateObject private var runManager = AutonomousRunManager()
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if viewModel.runMode == .connected {
                ConnectedRunView(viewModel: viewModel)
            } else {
                AutonomousRunView(runManager: runManager)
            }
        }
        .onAppear { runManager.requestPermissions() }
    }
}

// MARK: - Modo conectado

struct ConnectedRunView: View {
    @ObservedObject var viewModel: WatchViewModel
    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 0) {

            // Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("BLDR RUN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                Spacer()
                Image(systemName: "iphone")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Spacer(minLength: 6)

            // Distância (métrica principal)
            VStack(spacing: 2) {
                Text(viewModel.runDistanceFormatted)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text("quilômetros")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer(minLength: 6)

            // Pace + FC
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(viewModel.runPaceFormatted)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(kGold)
                    Text("pace/km")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 28)

                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.8))
                        Text(viewModel.runHeartRate > 0
                             ? "\(Int(viewModel.runHeartRate))"
                             : "--")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Text("bpm")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 8)

            // Controles
            HStack(spacing: 8) {
                Button {
                    WKInterfaceDevice.current().play(.click)
                    let acao = viewModel.isRunPaused ? "retomar" : "pausar"
                    viewModel.sendAction(["acao_corrida": acao])
                } label: {
                    Image(systemName: viewModel.isRunPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(kGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(kGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    WKInterfaceDevice.current().play(.stop)
                    showConfirm = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 44)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .confirmationDialog("Finalizar corrida?", isPresented: $showConfirm) {
            Button("Finalizar", role: .destructive) {
                viewModel.sendAction(["acao_corrida": "finalizar"])
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

// MARK: - Modo autônomo

struct AutonomousRunView: View {
    @ObservedObject var runManager: AutonomousRunManager
    @State private var showConfirm = false

    var body: some View {
        VStack(spacing: 0) {

            // Badge
            HStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 9))
                    .foregroundColor(.orange.opacity(0.8))
                Text("AUTÔNOMO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            if !runManager.isActive {
                // Tela de início
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 36))
                        .foregroundColor(kGold)

                    Text("BLDR Run")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Button {
                        WKInterfaceDevice.current().play(.start)
                        runManager.startRun()
                    } label: {
                        Text("Iniciar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(kGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
                Spacer()

            } else {
                // Corrida em andamento
                Spacer(minLength: 4)

                // Quando pausado: exibe tempo congelado via elapsedSeconds (@Published)
                // Quando ativo: timer nativo auto-avança sem Timer adicional
                if runManager.isPaused {
                    Text(runManager.formattedElapsed())
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .monospacedDigit()
                } else if let start = runManager.startDate {
                    Text(start, style: .timer)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }

                if runManager.isPaused {
                    Text("PAUSADO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                        .tracking(1)
                }

                Spacer(minLength: 4)

                // Métricas
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text(runManager.formattedDistance())
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(kGold)
                            .monospacedDigit()
                        Text("km")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text(runManager.formattedPace())
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Text("pace")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)

                    if runManager.heartRate > 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 1, height: 28)

                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.red.opacity(0.8))
                                Text("\(Int(runManager.heartRate))")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Text("bpm")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Spacer(minLength: 8)

                // Controles
                HStack(spacing: 8) {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        runManager.isPaused ? runManager.resumeRun() : runManager.pauseRun()
                    } label: {
                        Image(systemName: runManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(kGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(kGold.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button {
                        WKInterfaceDevice.current().play(.stop)
                        showConfirm = true
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 44)
                            .padding(.vertical, 11)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .confirmationDialog("Finalizar corrida?", isPresented: $showConfirm) {
            Button("Finalizar", role: .destructive) {
                WKInterfaceDevice.current().play(.success)
                let _ = runManager.finishRun()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}
