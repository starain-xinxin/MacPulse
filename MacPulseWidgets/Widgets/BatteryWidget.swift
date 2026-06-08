import SwiftUI
import WidgetKit

struct BatteryWidget: Widget {
    let kind = "BatteryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BatteryWidgetProvider()) { entry in
            BatteryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Battery")
        .description("Monitor battery status")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
