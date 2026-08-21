import WidgetKit
import SwiftUI
import ActivityKit

@main
struct BLDRWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen & Lock Screen widgets
        BLDRStreakWidget()
        BLDRCaloriasWidget()
        BLDRResumoWidget()
        BLDRDashboardWidget()
        BLDRRectangularWidget()

        // Live Activity
        if #available(iOS 16.1, *) {
            BLDRWorkoutLiveActivity()
        }
    }
}
