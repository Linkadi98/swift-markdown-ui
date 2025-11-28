import SwiftUI

@available(iOS 15.0, *)
struct ExpandableBlockSequence: View {
  @Environment(\.markdownMaxLines) private var maxLines

  // Per-block total line counts keyed by index
  @State private var blockLines: [Int: Int] = [:]

  private let blocks: [Indexed<BlockNode>]

  init(_ blocks: [BlockNode]) {
    self.blocks = blocks.indexed()
  }

  // Sum of measured lines before a given block
  private func consumedBefore(_ index: Int) -> Int {
    var total = 0
    for i in 0..<index { total += blockLines[i] ?? 0 }
    return total
  }

  // Determine desired line limit for a specific block so only the boundary is truncated
  private func lineLimitForBlock(index: Int) -> Int? {
    guard let maxLines else { return nil }  // unlimited
    let consumed = consumedBefore(index)
    guard consumed < maxLines else { return 0 }  // do not render
    let natural = blockLines[index] ?? 1  // default to 1 instead of .max
    if consumed + natural <= maxLines { return nil }  // full block, no truncation
    let remaining = maxLines - consumed
    return max(1, remaining)  // ensure at least 1 line, prevent overflow
  }

  var body: some View {
    // Visible pass with at-most-one truncated block
    VStack(alignment: .leading, spacing: 8) {
      ForEach(self.blocks, id: \.self) { element in
        let limit = self.lineLimitForBlock(index: element.index)
        if limit != 0 {  // render when we still have budget
          element.value
            .environment(\.markdownBlockIndex, element.index)
            .environment(\.markdownRemainingLines, limit == nil ? 1000 : limit!)
        }
      }
    }
    // Overlay measurement pass without affecting layout
    .overlay(
      VStack(alignment: .leading, spacing: 8) {
        ForEach(self.blocks, id: \.self) { element in
          element.value
            .environment(\.markdownBlockIndex, element.index)
            .environment(\.markdownRemainingLines, 1000)
        }
      }
      .allowsHitTesting(false)
      .opacity(0.001)
      .transaction { tx in tx.disablesAnimations = true }
    )
    .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
      self.blockLines = values
    }
  }
}
