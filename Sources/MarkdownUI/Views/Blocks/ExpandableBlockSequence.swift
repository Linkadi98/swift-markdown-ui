import SwiftUI

@available(iOS 15.0, *)
final class ExpandableBlockSequenceViewModel: ObservableObject {
    @Published var blockLines: [Int: Int] = [:]
    @Published var isMeasuredReady: Bool = false

    let totalBlocks: Int

    init(totalBlocks: Int) {
        self.totalBlocks = totalBlocks
    }

    func applyMeasuredLines(_ values: [Int: Int]) {
        // Ignore empty snapshots to avoid oscillation between [:] and measured values
        guard !values.isEmpty else { return }
        // Replace with the latest aggregated snapshot (BlockLinesPreferenceKey already sums by index)
        if values == blockLines { return }
        mdDbg("📊 applyMeasuredLines - snapshot: \(values)")
        blockLines = values
        // Mark ready as soon as we have any measurements; continue to refine as more arrive
        if !isMeasuredReady && values.count > 0 {
            isMeasuredReady = true
            mdDbg(
                "✅ Measurement started. Received \(values.count) of \(totalBlocks) block measurements"
            )
        }
    }

    func updateBlockLines(index: Int, lines: Int) {
        mdDbg("📏 measured block #\(index) -> \(lines) lines (\(blockLines.count)/\(totalBlocks))")
        var changed = false
        if blockLines[index] != lines {
            blockLines[index] = lines
            changed = true
        }
        // Mark ready only when all blocks have reported at least once
        isMeasuredReady = (blockLines.count >= totalBlocks)
        if changed {
            mdDbg(
                "📏 measured block #\(index) -> \(lines) lines (\(blockLines.count)/\(totalBlocks)) changed"
            )
        }
    }

    // Compute visible block indices along with their applicable line limits
    // Reserve at least `reserveForFirstContent` lines for the first content block (non-heading/non-rule)
    func visibleBlocks(
        totalBlockCount: Int,
        maxLines: Int?,
        isExpanded: Bool
    ) -> [(index: Int, limit: Int?)] {
        mdDbg(
            "🔍 visibleBlocks - totalBlockCount: \(totalBlockCount), maxLines: \(String(describing: maxLines)), isExpanded: \(isExpanded)"
        )
        if isExpanded || maxLines == nil {
            return (0..<totalBlockCount).map { (index: $0, limit: nil) }
        }
        guard let maxLines else { return [] }
        var remaining = maxLines
        var result: [(index: Int, limit: Int?)] = []
        for idx in 0..<totalBlockCount {
            let measured = blockLines[idx]
            // Treat known non-text structural blocks as zero-cost when not measured yet
            let fallback: Int = 1
            let contribution = max(0, measured ?? fallback)
            if contribution <= remaining {
                result.append((idx, nil))
                remaining -= contribution
            } else {
                if remaining > 0 { result.append((idx, remaining)) }
                break
            }
            if remaining <= 0 { break }
        }
        mdDbg("🔍 visibleBlocks - result: \(result.map { $0.index }), rem=\(remaining)")
        return result
    }
}

@available(iOS 15.0, *)
struct ExpandableBlockSequence: View {
    @Environment(\.markdownMaxLines) private var maxLines
    @Environment(\.markdownShouldExpand) private var isExpanded

    @StateObject private var viewModel: ExpandableBlockSequenceViewModel

    private let blocks: [Indexed<BlockNode>]

    init(_ blocks: [BlockNode]) {
        let indexed = blocks.indexed()
        self.blocks = indexed
        _viewModel = StateObject(
            wrappedValue: ExpandableBlockSequenceViewModel(totalBlocks: indexed.count))
        mdDbg("🎬 ExpandableBlockSequence init - totalBlocks: \(indexed.count)")
    }

    var body: some View {
        // Compute visible blocks using measured per-block line counts
        let visibleBlocks = viewModel.visibleBlocks(
            totalBlockCount: blocks.count,
            maxLines: maxLines,
            isExpanded: isExpanded
        )

        // Visible content: collapsed or expanded using measured/cached line counts
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(visibleBlocks, id: \.index) { block in
                let element = blocks[block.index]
                let remainingLines = block.limit ?? Int.max
                element.value
                    .environment(\.markdownBlockIndex, block.index)
                    .environment(\.markdownAggregateIndex, block.index)
                    .environment(\.markdownRemainingLines, remainingLines)
            }
        }
        // Start measurement immediately on appear without affecting layout
        .background(
            Group {
                if (!viewModel.isMeasuredReady) || (viewModel.blockLines.count < blocks.count)
                    || isExpanded
                {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(self.blocks, id: \.self) { element in
                            element.value
                                .environment(\.markdownBlockIndex, element.index)
                                .environment(\.markdownAggregateIndex, element.index)
                                .environment(\.markdownRemainingLines, 1000)
                        }
                    }
                    .opacity(0)
                    .allowsHitTesting(false)
                    .transaction { $0.disablesAnimations = true }
                }
            }
            // Collect inline-reported measurements from the measuring tree
            .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
                DispatchQueue.main.async {
                    viewModel.applyMeasuredLines(values)
                }
            }
        )
    }
}
