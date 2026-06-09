import SwiftUI
import WidgetKit

struct SystemStatsWidget: Widget {
    let kind = "SystemStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SystemStatsProvider()) { entry in
            SystemStatsWidgetView(entry: entry)
                .modifier(WidgetLanguageModifier())
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("CPU · RAM · Disk")
        .description("CPU and memory load with a detailed breakdown and free disk space.")
        .supportedFamilies([.systemMedium])
    }
}
