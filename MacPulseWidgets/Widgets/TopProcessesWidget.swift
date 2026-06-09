import SwiftUI
import WidgetKit

struct TopProcessesWidget: Widget {
    let kind = "TopProcessesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopProcessesProvider()) { entry in
            TopProcessesWidgetView(entry: entry)
                .modifier(WidgetLanguageModifier())
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Top Processes")
        .description("Monitor the apps using the most CPU and memory.")
        .supportedFamilies([.systemMedium])
    }
}
