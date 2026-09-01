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
            guard restShared.string(forKey: "\(prefix)activityType") != "run" else { continue }
            let currentEnd = restShared.double(forKey: "\(prefix)restEndTimestamp")
            let now = Date().timeIntervalSince1970
            // Se o tempo de fim já passou, extende a partir de agora; caso contrário, do fim atual
            let newEnd = (currentEnd > now ? currentEnd : now) + 15.0
            restShared.set(newEnd, forKey: "\(prefix)restEndTimestamp")
            let total = restShared.integer(forKey: "\(prefix)restTotalSeconds")
            restShared.set(total + 15, forKey: "\(prefix)restTotalSeconds")
            restShared.set("add", forKey: "bldr_rest_action")
            restShared.set(activity.id, forKey: "bldr_rest_action_activity_id")
            restShared.set(UUID().uuidString, forKey: "bldr_rest_action_id")
            restShared.set(newEnd, forKey: "bldr_rest_action_end")
            restShared.set(total + 15, forKey: "bldr_rest_action_total")
            restShared.set(Date().timeIntervalSince1970, forKey: "bldr_rest_action_timestamp")
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
            guard restShared.string(forKey: "\(prefix)activityType") != "run" else { continue }
            // Seta o fim do descanso para agora (countdown vira 0) e isResting para false
            restShared.set(Date().timeIntervalSince1970, forKey: "\(prefix)restEndTimestamp")
            restShared.set(false, forKey: "\(prefix)isResting")
            restShared.set("skip", forKey: "bldr_rest_action")
            restShared.set(activity.id, forKey: "bldr_rest_action_activity_id")
            restShared.set(UUID().uuidString, forKey: "bldr_rest_action_id")
            restShared.set(Date().timeIntervalSince1970, forKey: "bldr_rest_action_timestamp")
            let state = activity.content.state
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
        return .result()
    }
}
