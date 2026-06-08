import SwiftUI
import WidgetKit

struct MemoryWidget: Widget {
    let kind = "MemoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoryWidgetProvider()) { entry in
            MemoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Memory")
        .description("Monitor memory usage")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
