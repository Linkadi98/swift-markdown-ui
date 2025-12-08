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
      mdDbg("✅ Measurement started. Received \(values.count) of \(totalBlocks) block measurements")
    }
  }

  // Compute visible block indices along with their applicable line limits
  // Reserve at least `reserveForFirstContent` lines for the first content block (non-heading/non-rule)
  func visibleBlocks(
    totalBlockCount: Int,
    maxLines: Int?,
    isExpanded: Bool,
    isContentBlock: (_ index: Int) -> Bool,
    isHeadingBlock: (_ index: Int) -> Bool = { _ in false },
    isZeroCostBlock: (_ index: Int) -> Bool = { _ in false },
    reserveForFirstContent: Int = 0,
    headingCollapsedMaxLines: Int? = nil
  ) -> [(
    index: Int, limit: Int?
  )] {
    mdDbg("🔍 visibleBlocks - totalBlockCount: \(totalBlockCount), maxLines: \(String(describing: maxLines)), isExpanded: \(isExpanded)")

    if isExpanded || maxLines == nil {
      let result: [(index: Int, limit: Int?)] = (0..<totalBlockCount).map {
        (idx) -> (index: Int, limit: Int?) in
        (index: idx, limit: nil)
      }
      mdDbg("🔍 visibleBlocks - returning all: \(result.map { $0.index })")
      return result
    }
    guard let maxLines else { return [] }
    var remaining = maxLines
    var firstContentShown = false
    var result: [(index: Int, limit: Int?)] = []
    for idx in 0..<totalBlockCount {
      var limit: Int?
      let contentBlock = isContentBlock(idx)
      if let measuredRaw = blockLines[idx] {
        // Optionally clamp heading contribution to a configurable max in collapsed mode
        let measured: Int
        if isHeadingBlock(idx), let cap = headingCollapsedMaxLines {
          measured = min(measuredRaw, cap)
        } else {
          measured = measuredRaw
        }
        // We have a measured line count for this block
        if !firstContentShown && !contentBlock {
          // Heading/rule before first content: reserve some lines for first content
          let reserve = max(0, reserveForFirstContent)
          let usable = max(0, remaining - reserve)
          if measured <= usable {
            limit = nil
            remaining -= measured
          } else if usable > 0 {
            limit = usable
            remaining = reserve
          } else {
            limit = 0
          }
        } else {
          if measured <= remaining {
            limit = nil
            remaining -= measured
          } else if remaining > 0 {
            limit = remaining
            remaining = 0
          } else {
            limit = 0
          }
        }
      } else {
        // Fallback assumption until measurement is ready: assume 1 line per block
        let assumed: Int = isZeroCostBlock(idx) ? 0 : 1
        if !firstContentShown && !contentBlock {
          let reserve = max(0, reserveForFirstContent)
          let usable = max(0, remaining - reserve)
          if assumed <= usable {
            limit = nil
            remaining -= assumed
          } else if usable > 0 {
            limit = usable
            remaining = reserve
          } else {
            limit = 0
          }
        } else {
          if assumed <= remaining {
            limit = nil
            remaining -= assumed
          } else if remaining > 0 {
            limit = remaining
            remaining = 0
          } else {
            limit = 0
          }
        }
      }
      if limit != 0 {
        result.append((idx, limit))
      }
      if contentBlock && (limit == nil || (limit ?? 0) > 0) {
        firstContentShown = true
      }
      if remaining <= 0 {
        break
      }
    }
    mdDbg("🔍 visibleBlocks - result: \(result.map { $0.index })")
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
    // Decide which blocks are "content" (consume budget) vs structural
    let isContentBlock: (Int) -> Bool = { i in
      switch blocks[i].value {
      case .heading, .thematicBreak: return false
      default: return true
      }
    }

    // Compute visible blocks before building the view tree
    let visibleBlocks = viewModel.visibleBlocks(
      totalBlockCount: blocks.count,
      maxLines: maxLines,
      isExpanded: isExpanded,
      isContentBlock: isContentBlock,
      isHeadingBlock: { i in
        if case .heading = blocks[i].value { return true } else { return false }
      },
      isZeroCostBlock: { i in
        if case .thematicBreak = blocks[i].value { return true }
        return false
      },
      reserveForFirstContent: 0,
      headingCollapsedMaxLines: nil
    )

    // Visible content: collapsed or expanded using measured/cached line counts
    return VStack(alignment: .leading, spacing: 8) {
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
