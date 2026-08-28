import ActivityKit
import AppIntents

private let restShared = UserDefaults(suiteName: "group.com.bldr.fitness")!

// MARK: - +15s

@available(iOS 17.0, *)
struct BLDRAddRestTimeIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Adicionar 15s de descanso"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivitiesAppAttributes>.activities {
            let prefix = "\(activity.attributes.id)_"
            let currentEnd = restShared.double(forKey: "\(prefix)restEndTimestamp")
            let now = Date().timeIntervalSince1970
            // Se o tempo de fim já passou, extende a partir de agora; caso contrário, do fim atual
            let newEnd = (currentEnd > now ? currentEnd : now) + 15.0
            restShared.set(newEnd, forKey: "\(prefix)restEndTimestamp")
            let total = restShared.integer(forKey: "\(prefix)restTotalSeconds")
            restShared.set(total + 15, forKey: "\(prefix)restTotalSeconds")
            let state = activity.content.state
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
        return .result()
    }
}

// MARK: - Pular descanso

@available(iOS 17.0, *)
struct BLDRSkipRestIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Pular descanso"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        for activity in Activity<LiveActivitiesAppAttributes>.activities {
            let prefix = "\(activity.attributes.id)_"
            // Seta o fim do descanso para agora (countdown vira 0) e isResting para false
            restShared.set(Date().timeIntervalSince1970, forKey: "\(prefix)restEndTimestamp")
            restShared.set(false, forKey: "\(prefix)isResting")
            let state = activity.content.state
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
        return .result()
    }
}
