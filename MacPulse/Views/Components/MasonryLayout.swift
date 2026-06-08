import SwiftUI

struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(
            in: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        for (index, placement) in result.placements.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + placement.origin.x,
                    y: bounds.minY + placement.origin.y
                ),
                proposal: ProposedViewSize(width: placement.size.width, height: placement.size.height)
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var placements: [(origin: CGPoint, size: CGSize)]
    }

    private func layout(in proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let totalWidth = proposal.width ?? 600
        let columnWidth = (totalWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = Array(repeating: CGFloat(0), count: columns)
        var placements: [(origin: CGPoint, size: CGSize)] = []

        for subview in subviews {
            // Find the shortest column
            let shortestColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })!.offset
            let proposedSize = ProposedViewSize(width: columnWidth, height: nil)
            let size = subview.sizeThatFits(proposedSize)

            let x = CGFloat(shortestColumn) * (columnWidth + spacing)
            let y = columnHeights[shortestColumn]

            placements.append((
                origin: CGPoint(x: x, y: y),
                size: CGSize(width: columnWidth, height: size.height)
            ))

            columnHeights[shortestColumn] += size.height + spacing
        }

        let maxHeight = columnHeights.max() ?? 0
        return LayoutResult(
            size: CGSize(width: totalWidth, height: max(maxHeight - spacing, 0)),
            placements: placements
        )
    }
}
