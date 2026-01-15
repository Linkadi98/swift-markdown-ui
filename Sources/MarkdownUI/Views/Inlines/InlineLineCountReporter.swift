import SwiftUI

@available(iOS 15.0, *)
private struct InlineLineCountReporter: View {
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownBlockIndex) private var blockIndex
  @Environment(\.markdownAggregateIndex) private var aggregateIndex

  let content: Text

  @State private var totalHeight: CGFloat = 0
  @State private var singleLineHeight: CGFloat = 0
  @State private var twoLineHeight: CGFloat = 0

  init(_ content: Text) {
    self.content = content
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      content
        .lineLimit(remainingLines >= 1000 ? nil : remainingLines)
        .truncationMode(.tail)
        .allowsTightening(true)
        .background(
          GeometryReader { proxy in
            Color.clear.onAppear { totalHeight = proxy.size.height }
              .onChange(of: proxy.size.height) { totalHeight = $0 }
          }
        )

      content
        .lineLimit(1)
        .truncationMode(.tail)
        .allowsTightening(true)
        .opacity(0.001)
        .accessibilityHidden(true)
        .background(
          GeometryReader { proxy in
            Color.clear.onAppear { singleLineHeight = max(1, proxy.size.height) }
              .onChange(of: proxy.size.height) { singleLineHeight = max(1, $0) }
          }
        )

      content
        .lineLimit(2)
        .truncationMode(.tail)
        .allowsTightening(true)
        .opacity(0.001)
        .accessibilityHidden(true)
        .background(
          GeometryReader { proxy in
            Color.clear.onAppear { twoLineHeight = max(1, proxy.size.height) }
              .onChange(of: proxy.size.height) { twoLineHeight = max(1, $0) }
          }
        )
    }
    .background(
      Group {
        if remainingLines >= 1000 {
          Color.clear.preference(
            key: BlockLinesPreferenceKey.self,
            value: [self.publishIndex(): self.computeUsedLines()]
          )
        } else {
          Color.clear.preference(key: BlockLinesPreferenceKey.self, value: [:])
        }
      }
    )
  }

  private func publishIndex() -> Int {
    let idx = aggregateIndex >= 0 ? aggregateIndex : blockIndex
    return idx >= 0 ? idx : 0
  }

  private func computeUsedLines() -> Int {
    let h = totalHeight
    let h1 = singleLineHeight
    let h2 = twoLineHeight
    guard h > 0 else { return 1 }
    if h2 > h1, h1 >= 4 {
      let perLine = max(1, h2 - h1)
      let extra = max(0, h - h1)
      let lines = 1 + Int(ceil(extra / perLine))
      return max(1, lines)
    }
    if h1 >= 4 {
      return max(1, Int(ceil(h / h1)))
    }
    #if canImport(UIKit)
      let lh = UIFont.preferredFont(forTextStyle: .body).lineHeight
      guard lh > 0 else { return 1 }
      return max(1, Int(ceil(h / lh)))
    #else
      return max(1, Int(ceil(h / 20)))
    #endif
  }
}

@available(iOS 15.0, *)
extension Text {
  /// Apply a modifier that reports measured line usage for the current block via
  /// `BlockLinesPreferenceKey`. Publishing happens only during the measuring pass
  /// (when `markdownRemainingLines >= 1000`).
  func reportInlineLineCount() -> some View {
    InlineLineCountReporter(self)
  }
}
