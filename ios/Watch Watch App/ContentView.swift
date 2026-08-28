import SwiftUI

private let kGold = Color(red: 0.831, green: 0.686, blue: 0.216)

// MARK: - Root

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()

    var body: some View {
        TabView {
            WorkoutTabView(viewModel: viewModel)
            RunTabView(viewModel: viewModel)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

// MARK: - Tab wrappers

struct WorkoutTabView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if viewModel.listaExercicios.isEmpty {
                WorkoutIdleView()
            } else {
                WorkoutActiveView(viewModel: viewModel)
            }
        }
    }
}

struct RunTabView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        RunView(viewModel: viewModel)
    }
}

// MARK: - Sem treino ativo

struct WorkoutIdleView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 28))
                .foregroundColor(kGold)

            Text("BLDR")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(kGold)
                .tracking(2)

            Text("Inicie um treino\nno iPhone")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Treino ativo

struct WorkoutActiveView: View {
    @ObservedObject var viewModel: WatchViewModel
    @State private var hapticSerie = false
    @State private var hapticStop = false

    var body: some View {
        VStack(spacing: 0) {

            // Header: nome + timer
            HStack {
                Text(viewModel.workoutName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(kGold)
                    .lineLimit(1)
                Spacer()
                if let start = viewModel.workoutStartDate {
                    Text(start, style: .timer)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.vertical, 6)

            // Exercício atual
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.exerciseName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Label(viewModel.seriesLabel, systemImage: "repeat")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    if !viewModel.currentBpm.isEmpty {
                        Label(viewModel.currentBpm, systemImage: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            Spacer(minLength: 8)

            // Botões
            HStack(spacing: 8) {
                Button {
                    hapticSerie.toggle()
                    viewModel.concluirSerie()
                } label: {
                    Label("Série", systemImage: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(kGold)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    hapticStop.toggle()
                    viewModel.finalizarTreino()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 40)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .sensoryFeedback(.impact(weight: .medium), trigger: hapticSerie)
        .sensoryFeedback(.warning, trigger: hapticStop)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
