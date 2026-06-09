import SwiftUI

struct MetricRowView: View {
    let label: LocalizedStringKey
    private let value: String?
    private let localizedValue: LocalizedStringKey?
    let icon: String?
    let valueColor: Color

    init(
        label: LocalizedStringKey,
        value: String,
        icon: String? = nil,
        valueColor: Color = .primary
    ) {
        self.label = label
        self.value = value
        localizedValue = nil
        self.icon = icon
        self.valueColor = valueColor
    }

    init(
        label: LocalizedStringKey,
        localizedValue: LocalizedStringKey,
        icon: String? = nil,
        valueColor: Color = .primary
    ) {
        self.label = label
        value = nil
        self.localizedValue = localizedValue
        self.icon = icon
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
            Text(label)
                .foregroundStyle(.secondary)
                .font(.caption)
            Spacer()
            Group {
                if let localizedValue {
                    Text(localizedValue)
                } else if let value {
                    Text(value)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .monospacedDigit()
            .foregroundStyle(valueColor)
        }
    }
}
