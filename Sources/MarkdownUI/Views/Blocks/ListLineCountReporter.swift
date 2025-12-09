import SwiftUI

@available(iOS 15.0, *)
struct ListLineCountReporter<Content: View>: View {
  @Environment(\.markdownBlockIndex) private var blockIndex
  @Environment(\.markdownAggregateIndex) private var aggregateIndex
  @Environment(\.markdownRemainingLines) private var remainingLines

  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .background(
        GeometryReader { geometry in
          Color.clear.preference(
            key: BlockLinesPreferenceKey.self,
            value: self.shouldPublish
              ? [self.publishIndex(): self.computeUsedLines(height: geometry.size.height)] : [:]
          )
        }
      )
  }

  private var shouldPublish: Bool {
    // Only publish during measuring pass to avoid render loops
    remainingLines >= 1000
  }

  private func publishIndex() -> Int {
    // Prefer aggregate index for nested content
    aggregateIndex ?? blockIndex ?? 0
  }

  private func computeUsedLines(height: CGFloat) -> Int {
    // For lists, use a simple heuristic: assume 20pt per line
    // This is approximate but works for most cases
    let estimatedLineHeight: CGFloat = 20.0
    let lines = max(1, Int(ceil(height / estimatedLineHeight)))
    mdDbg("📊 ListLineCountReporter - height: \(height), lines: \(lines)")
    return lines
  }
}
