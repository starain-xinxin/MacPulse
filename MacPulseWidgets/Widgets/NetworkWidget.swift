import SwiftUI
import WidgetKit

struct NetworkWidget: Widget {
    let kind = "NetworkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetworkWidgetProvider()) { entry in
            NetworkWidgetView(entry: entry)
                .modifier(WidgetLanguageModifier())
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Network")
        .description("Monitor network status")
        .supportedFamilies([.systemMedium])
    }
}
