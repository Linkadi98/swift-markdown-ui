import SwiftUI

@available(iOS 15.0, *)
final class ExpandableBlockSequenceViewModel: ObservableObject {
    @Published var blockLines: [Int: Int] = [:]
    @Published var isMeasuredReady: Bool = false
    @Published var isMeasuring: Bool = true

    private var stopMeasuringWorkItem: DispatchWorkItem?

    let totalBlocks: Int

    init(totalBlocks: Int) {
        self.totalBlocks = totalBlocks
    }

    func applyMeasuredLines(_ values: [Int: Int]) {
        // Ignore empty snapshots to avoid oscillation between [:] and measured values
        guard !values.isEmpty else { return }
        // Merge with existing using monotonic non-decreasing counts to avoid flapping
        // when multiple measuring passes produce slightly different numbers.
        var merged = blockLines
        for (k, v) in values {
            merged[k] = max(v, merged[k] ?? 0)
        }
        if merged == blockLines { return }
        mdDbg("📊 applyMeasuredLines - snapshot: \(values)")
        blockLines = merged
        // Mark ready as soon as we have any measurements; continue to refine as more arrive
        if !isMeasuredReady && values.count > 0 {
            isMeasuredReady = true
            mdDbg(
                "✅ Measurement started. Received \(values.count) of \(totalBlocks) block measurements"
            )
        }

        // Stop the hidden measuring tree once measurements have been stable for a short period.
        // Some block types don't publish line counts, so waiting for count == totalBlocks
        // would keep measuring forever for long documents.
        if !isMeasuring { isMeasuring = true }
        stopMeasuringWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.isMeasuring = false
        }
        stopMeasuringWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
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
        blocks: [Indexed<BlockNode>],
        maxLines: Int?,
        isExpanded: Bool
    ) -> [(index: Int, limit: Int?)] {
        mdDbg(
            "🔍 visibleBlocks - totalBlockCount: \(blocks.count), maxLines: \(String(describing: maxLines)), isExpanded: \(isExpanded)"
        )
        if isExpanded || maxLines == nil {
            return (0..<blocks.count).map { (index: $0, limit: nil) }
        }
        guard let maxLines else { return [] }
        var remaining = maxLines
        var result: [(index: Int, limit: Int?)] = []
        for idx in 0..<blocks.count {
            let measured = blockLines[idx]
            let contribution = max(
                0, measured ?? fallbackContribution(for: blocks[idx].value, remaining: remaining))
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

    private func fallbackContribution(for block: BlockNode, remaining: Int) -> Int {
        // Conservative defaults to avoid showing too much content before measurement arrives.
        // This makes collapsed height grow (not shrink) as we refine measurements.
        switch block {
        case .thematicBreak:
            return 0
        case .heading:
            return 1
        case .htmlBlock:
            return 1
        case .codeBlock:
            // Force partial rendering until measured.
            return remaining + 1
        case .table:
            return remaining + 1
        case .blockquote, .bulletedList, .numberedList, .taskList, .paragraph:
            return remaining + 1
        }
    }
}

@available(iOS 15.0, *)
struct ExpandableBlockSequence: View {
    private let blocks: [BlockNode]
    private let blocksIdentity: Int

    init(_ blocks: [BlockNode]) {
        self.blocks = blocks
        self.blocksIdentity = blocks.hashValue
    }

    var body: some View {
        ExpandableBlockSequenceImpl(self.blocks)
            .id(self.blocksIdentity)
    }
}

@available(iOS 15.0, *)
private struct ExpandableBlockSequenceImpl: View {
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
            blocks: blocks,
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
                // Avoid measuring when used by the full-height probe (maxLines == nil)
                // to prevent duplicate BlockLinesPreferenceKey emissions.
                if (viewModel.isMeasuring && maxLines != nil) || isExpanded {
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
