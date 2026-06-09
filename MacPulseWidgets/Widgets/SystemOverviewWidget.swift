import SwiftUI
import WidgetKit

struct SystemOverviewWidget: Widget {
    let kind = "SystemOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SystemOverviewProvider()) { entry in
            SystemOverviewWidgetView(entry: entry)
                .modifier(WidgetLanguageModifier())
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("System Overview")
        .description("Overview of CPU, memory, disk, and battery")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
