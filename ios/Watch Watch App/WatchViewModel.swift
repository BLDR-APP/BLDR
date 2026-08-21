import Foundation
import WatchConnectivity
import SwiftUI
import Combine

// Modelo simples para a lista
struct Exercicio: Identifiable {
    let id = UUID()
    let nome: String
    let series: Int
    let reps: String
    let info: String
}

enum WatchRunMode {
    case connected   // iPhone acessível — Watch como display
    case autonomous  // iPhone não acessível — Watch independente
}

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {

    // MARK: — Treino de força (existente)
    @Published var treinoNome: String = "Sem treino ativo"
    @Published var status: String = "--"
    @Published var corStatus: Color = .gray
    @Published var listaExercicios: [Exercicio] = []

    // MARK: — Propriedades para nova UI
    @Published var workoutStartDate: Date? = nil
    @Published var exerciseName: String = "—"
    @Published var seriesLabel: String = "—"
    @Published var currentBpm: String = ""

    var workoutName: String { treinoNome }

    // MARK: — Corrida (modo conectado)
    @Published var runDistanceFormatted: String = "0.00 km"
    @Published var runPaceFormatted: String = "--:--/km"
    @Published var runHeartRate: Double = 0
    @Published var isRunPaused: Bool = false

    // MARK: — Modo de corrida
    var runMode: WatchRunMode {
        WCSession.default.isReachable ? .connected : .autonomous
    }

    private var session: WCSession { WCSession.default }

    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: — Ações treino de força

    func concluirSerie() {
        sendMessageToiPhone(["acao": "concluir_serie"])
    }

    func finalizarTreino() {
        sendMessageToiPhone(["acao": "finalizar_treino"])
        limparTela()
    }

    private func limparTela() {
        DispatchQueue.main.async {
            self.treinoNome = "Sem treino ativo"
            self.listaExercicios = []
            self.status = "Concluído"
            self.corStatus = .gray
            self.workoutStartDate = nil
            self.exerciseName = "—"
            self.seriesLabel = "—"
            self.currentBpm = ""
        }
    }

    private func sendMessageToiPhone(_ data: [String: Any]) {
        guard session.isReachable else { return }
        session.sendMessage(data, replyHandler: nil, errorHandler: nil)
    }

    // MARK: — Ações corrida (modo conectado → envia ao iPhone)

    func sendAction(_ message: [String: Any]) {
        guard session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: — Sincronização de corridas autônomas pendentes

    func syncPendingRuns() {
        guard session.isReachable else { return }
        guard let dict = UserDefaults(suiteName: "group.com.bldr.fitness")?.dictionaryRepresentation() else { return }

        let pendingKeys = dict.keys.filter { $0.hasPrefix("pending_run_") }
        guard !pendingKeys.isEmpty else { return }

        let defaults = UserDefaults(suiteName: "group.com.bldr.fitness")!
        for key in pendingKeys {
            guard let data = defaults.data(forKey: key) else { continue }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(key).json")
            do {
                try data.write(to: tempURL)
                session.transferFile(tempURL, metadata: ["type": "run_data"])
                defaults.removeObject(forKey: key)
                print("[BLDR] Corrida transferida: \(key)")
            } catch {
                print("[BLDR] Erro ao transferir corrida: \(error)")
            }
        }
    }

    // MARK: — WCSession Delegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            if !session.receivedApplicationContext.isEmpty {
                self.processarDados(session.receivedApplicationContext)
            }
            // Sincronizar corridas pendentes ao ativar sessão
            if activationState == .activated {
                self.syncPendingRuns()
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            syncPendingRuns()
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        processarDados(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processarDados(message)
    }

    // MARK: — Processamento de dados recebidos

    private func processarDados(_ data: [String: Any]) {
        DispatchQueue.main.async {
            print("📦 Watch recebeu dados: \(data)")

            // --- Dados de corrida ---
            if let run = data["corrida"] as? [String: Any] {
                if let d = run["distance"] as? Double {
                    self.runDistanceFormatted = String(format: "%.2f km", d / 1000)
                }
                if let p = run["pace"] as? Double, p > 0 {
                    let min = Int(p) / 60
                    let sec = Int(p) % 60
                    self.runPaceFormatted = String(format: "%d:%02d/km", min, sec)
                }
                self.runHeartRate = run["hr"] as? Double ?? 0
                self.isRunPaused = !(run["active"] as? Bool ?? true)
                if run["finished"] as? Bool == true {
                    self.runDistanceFormatted = "0.00 km"
                    self.runPaceFormatted = "--:--/km"
                    self.runHeartRate = 0
                    self.isRunPaused = false
                }
                return
            }

            // --- Dados de treino de força ---
            if let status = data["status"] as? String, status == "finished" {
                self.limparTela()
                return
            }

            if let exerciciosRaw = data["exercicios"] as? [[String: Any]], exerciciosRaw.isEmpty {
                if let bpm = data["bpm"] as? String, bpm != "Iniciando..." {
                    self.limparTela()
                    return
                }
            }

            if let nome = data["treino"] as? String {
                self.treinoNome = nome
                self.corStatus = Color(red: 212/255, green: 175/255, blue: 55/255)
                if self.workoutStartDate == nil {
                    self.workoutStartDate = Date()
                }
            }

            if let bpm = data["bpm"] as? String, bpm != "Iniciando..." {
                self.status = bpm
                self.currentBpm = bpm
            } else if self.status == "--" || self.status == "Concluído" {
                self.status = "Ativo"
                self.currentBpm = ""
            }

            if let exerciciosRaw = data["exercicios"] as? [[String: Any]] {
                self.listaExercicios = exerciciosRaw.map { item in
                    let series = item["series"] as? Int ?? 3
                    let reps = "\(item["reps"] ?? "-")"
                    let duracao = item["duracao_segundos"] as? Int
                    let infoText = duracao != nil
                        ? "\(series) séries x \(duracao!)s"
                        : "\(series) séries x \(reps)"
                    return Exercicio(
                        nome: item["nome"] as? String ?? "Exercício",
                        series: series,
                        reps: reps,
                        info: infoText
                    )
                }
                // Alimenta propriedades da nova UI com o exercício atual
                if let primeiro = exerciciosRaw.first {
                    self.exerciseName = primeiro["nome"] as? String ?? "—"
                    let s = primeiro["series"] as? Int ?? 0
                    let r = "\(primeiro["reps"] ?? "-")"
                    self.seriesLabel = "\(s)x\(r)"
                }
            }
        }
    }
}
