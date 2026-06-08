import SwiftUI

struct UsageBarView: View {
    let segments: [(label: String, value: Double, color: Color)]
    var height: CGFloat = 12

    private var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    let width = total > 0
                        ? CGFloat(segment.value / total) * geo.size.width
                        : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segment.color)
                        .frame(width: max(width, 0))
                }
            }
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.quaternary)
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct SimpleBarView: View {
    let value: Double
    let color: Color
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.15))

                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(CGFloat(min(value, 1.0)) * geo.size.width, 0))
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
        .frame(height: height)
    }
}
