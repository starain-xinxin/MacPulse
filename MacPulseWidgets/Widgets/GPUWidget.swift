import SwiftUI
import WidgetKit

struct GPUWidget: Widget {
    let kind = "GPUWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GPUWidgetProvider()) { entry in
            GPUWidgetView(entry: entry)
                .modifier(WidgetLanguageModifier())
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("GPU")
        .description("GPU usage, temperature, and thermal pressure.")
        .supportedFamilies([.systemMedium])
    }
}
