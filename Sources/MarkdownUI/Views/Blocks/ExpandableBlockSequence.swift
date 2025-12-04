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

  // Compute visible block indices along with their applicable line limits
  func visibleBlocks(totalBlockCount: Int, maxLines: Int?, isExpanded: Bool) -> [(
    index: Int, limit: Int?
  )] {
    print(
      "🔍 visibleBlocks - totalBlockCount: \(totalBlockCount), maxLines: \(String(describing: maxLines)), isExpanded: \(isExpanded)"
    )

    if isExpanded || maxLines == nil {
      let result: [(index: Int, limit: Int?)] = (0..<totalBlockCount).map {
        (idx) -> (index: Int, limit: Int?) in
        (index: idx, limit: nil)
      }
      print("🔍 visibleBlocks - returning all: \(result.map { $0.index })")
      return result
    }
    guard let maxLines else { return [] }
    var remaining = maxLines
    var result: [(index: Int, limit: Int?)] = []
    for idx in 0..<totalBlockCount {
      var limit: Int?
      if let measured = blockLines[idx] {
        if measured <= remaining {
          limit = nil
          remaining -= measured
        } else if remaining > 0 {
          limit = remaining
          remaining = 0
        } else {
          limit = 0
        }
      } else {
        if remaining > 0 {
          limit = remaining
          remaining = 0
        } else {
          limit = 0
        }
      }
      if limit != 0 {
        result.append((idx, limit))
      }
      if remaining <= 0 {
        break
      }
    }
    print("🔍 visibleBlocks - result: \(result.map { $0.index })")
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
    print("🎬 ExpandableBlockSequence init - totalBlocks: \(indexed.count)")
  }

  var body: some View {
    // Visible content: collapsed or expanded using measured/cached line counts
    VStack(alignment: .leading, spacing: 8) {
      let visibleBlocks = viewModel.visibleBlocks(
        totalBlockCount: blocks.count,
        maxLines: maxLines,
        isExpanded: isExpanded
      )

      ForEach(visibleBlocks, id: \.index) { block in
        let element = blocks[block.index]
        let remainingLines = block.limit ?? Int.max
        element.value
          .environment(\.markdownBlockIndex, block.index)
          .environment(\.markdownRemainingLines, remainingLines)
      }
    }
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
      DispatchQueue.main.async {
        viewModel.applyMeasuredLines(values)
      }
    }
  }
}
