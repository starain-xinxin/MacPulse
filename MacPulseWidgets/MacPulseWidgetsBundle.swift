import SwiftUI
import WidgetKit

@main
struct MacPulseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CPUWidget()
        MemoryWidget()
        BatteryWidget()
        NetworkWidget()
        SystemOverviewWidget()
    }
}
