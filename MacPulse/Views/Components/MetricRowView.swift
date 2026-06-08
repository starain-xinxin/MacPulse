import SwiftUI

struct MetricRowView: View {
    let label: String
    let value: String
    var icon: String? = nil
    var valueColor: Color = .primary

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
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
    }
}
