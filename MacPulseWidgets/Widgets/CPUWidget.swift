import SwiftUI
import WidgetKit

struct CPUWidget: Widget {
    let kind = "CPUWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CPUWidgetProvider()) { entry in
            CPUWidgetView(entry: entry)
                .modifier(WidgetLanguageModifier())
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("CPU")
        .description("Monitor CPU usage")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
