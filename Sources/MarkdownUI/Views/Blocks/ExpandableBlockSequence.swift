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
        // Ignore if identical
        if values == blockLines { return }
        
        print("📊 applyMeasuredLines - incoming: \(values)")
        
        // Merge, prefer larger (natural counts shouldn't shrink)
        var merged = blockLines
        for (k, v) in values {
            if let old = merged[k] {
                merged[k] = max(old, v)
            } else {
                merged[k] = v
            }
        }
        blockLines = merged
        
        print("📊 applyMeasuredLines - merged: \(merged), ready: \(isMeasuredReady)")
        
        if !isMeasuredReady && merged.count >= totalBlocks { 
            isMeasuredReady = true 
            print("✅ Measurement ready! Total blocks: \(totalBlocks)")
        }
    }
    
    // Sum of measured lines before a given block
    func consumedBefore(_ index: Int) -> Int {
        var total = 0
        for i in 0..<index { total += blockLines[i] ?? 0 }
        return total
    }
    
    // Determine desired line limit for a specific block so only the boundary is truncated
    func lineLimitForBlock(index: Int, maxLines: Int?, isExpanded: Bool) -> Int? {
        guard let maxLines, !isExpanded else { return nil }  // unlimited
        let consumed = consumedBefore(index)
        guard consumed < maxLines else { return 0 }  // do not render
        let natural = blockLines[index] ?? 1  // default to 1
        if consumed + natural <= maxLines { return nil }  // full block, no truncation
        let remaining = maxLines - consumed
        return max(1, remaining)  // ensure at least 1 line, prevent overflow
    }
    
    // Compute visible block indices based on truncation logic
    func visibleBlockIndices(totalBlockCount: Int, maxLines: Int?, isExpanded: Bool) -> [Int] {
        print("🔍 visibleBlockIndices - totalBlockCount: \(totalBlockCount), maxLines: \(String(describing: maxLines)), isExpanded: \(isExpanded)")
        
        if isExpanded || maxLines == nil {
            let result = Array(0..<totalBlockCount)
            print("🔍 visibleBlockIndices - returning all: \(result)")
            return result
        }
        var result: [Int] = []
        for idx in 0..<totalBlockCount {
            let limit = lineLimitForBlock(index: idx, maxLines: maxLines, isExpanded: isExpanded)
            if limit != 0 {
                result.append(idx)
            }
        }
        print("🔍 visibleBlockIndices - filtered result: \(result)")
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
        _viewModel = StateObject(wrappedValue: ExpandableBlockSequenceViewModel(totalBlocks: indexed.count))
        print("🎬 ExpandableBlockSequence init - totalBlocks: \(indexed.count)")
    }
    
    var body: some View {
        // Visible content: collapsed or expanded using measured/cached line counts
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isMeasuredReady {
                let visibleIndices = viewModel.visibleBlockIndices(
                    totalBlockCount: blocks.count,
                    maxLines: maxLines,
                    isExpanded: isExpanded
                )
                
                ForEach(visibleIndices, id: \.self) { idx in
                    let element = blocks[idx]
                    let limit = viewModel.lineLimitForBlock(index: idx, maxLines: maxLines, isExpanded: isExpanded)
                    if limit != 0 {
                        element.value
                            .environment(\.markdownBlockIndex, idx)
                            .environment(\.markdownRemainingLines, limit == nil ? 1000 : limit!)
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        // Start measurement immediately on appear without affecting layout
        .background(
            Group {
                if !viewModel.isMeasuredReady || isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(self.blocks, id: \.self) { element in
                            element.value
                                .environment(\.markdownBlockIndex, element.index)
                                .environment(\.markdownRemainingLines, 1000)
                        }
                    }
                    .opacity(0)
                    .allowsHitTesting(false)
                    .transaction { $0.disablesAnimations = true }
                }
            }
        )
        .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
            viewModel.applyMeasuredLines(values)
        }
    }
}
