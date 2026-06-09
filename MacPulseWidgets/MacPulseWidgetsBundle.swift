import SwiftUI
import WidgetKit

@main
struct MacPulseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GPUWidget()
        NetworkWidget()
        SystemStatsWidget()
        TopProcessesWidget()
    }
}
