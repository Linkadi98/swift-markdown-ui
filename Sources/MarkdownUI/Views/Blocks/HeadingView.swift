import SwiftUI

@available(iOS 15.0, *)
struct HeadingView: View {
  @Environment(\.theme.headings) private var headings
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownBlockIndex) private var blockIndex
  @State private var totalHeight: CGFloat = 0
  @State private var singleLineHeight: CGFloat = 0
  @State private var twoLineHeight: CGFloat = 0

  private let level: Int
  private let content: [InlineNode]

  init(level: Int, content: [InlineNode]) {
    self.level = level
    self.content = content
  }

  var body: some View {
    self.headings[self.level - 1].makeBody(
      configuration: .init(
        label: .init(self.measuredLabel),
        content: .init(block: .heading(level: self.level, content: self.content))
      )
    )
    .id(content.renderPlainText().kebabCased())
  }

  @ViewBuilder private var measuredLabel: some View {
    TextStyleAttributesReader { _ in
      ZStack(alignment: .topLeading) {
        // Unlimited (when measuring) or budgeted (when rendering) content
        InlineText(self.content)
          .lineLimit(self.remainingLines >= 1000 ? nil : self.remainingLines)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { totalHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { totalHeight = $0 }
            }
          )

        // Hidden one-line probe to get accurate single line height for the same style
        InlineText(self.content)
          .lineLimit(1)
          .opacity(0.001)
          .accessibilityHidden(true)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { singleLineHeight = max(1, proxy.size.height) }
                .onChange(of: proxy.size.height) { singleLineHeight = max(1, $0) }
            }
          )

        // Hidden two-line probe to compute incremental per-line height (cancels paddings)
        InlineText(self.content)
          .lineLimit(2)
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
        // Publish computed lines using current measurements
        Group {
          if self.remainingLines >= 1000 {
            Color.clear.preference(
              key: BlockLinesPreferenceKey.self,
              value: [self.blockIndex: self.computeUsedLines()]
            )
          } else {
            Color.clear.preference(key: BlockLinesPreferenceKey.self, value: [:])
          }
        }
      )
    }
  }

  private func estimateUsedLines(proxy: GeometryProxy) -> Int {
    #if canImport(UIKit)
      let textStyle: UIFont.TextStyle
      switch level {
      case 1: textStyle = .largeTitle
      case 2: textStyle = .title1
      case 3: textStyle = .title2
      case 4: textStyle = .title3
      case 5: textStyle = .headline
      default: textStyle = .subheadline
      }
      let lh = UIFont.preferredFont(forTextStyle: textStyle).lineHeight
    #else
      let lh: CGFloat = {
        switch level {
        case 1: return 34
        case 2: return 28
        case 3: return 24
        case 4: return 22
        case 5: return 20
        default: return 18
        }
      }()
    #endif
    let h = proxy.size.height
    guard lh > 0 else { return 0 }
    return max(1, Int(ceil(h / lh)))
  }

  private func computeUsedLines() -> Int {
    let h = totalHeight
    let h1 = singleLineHeight
    let h2 = twoLineHeight
    guard h > 0, h1 > 0 else { return 1 }
    // If we have a reliable two-line probe, use incremental height to cancel paddings
    if h2 > h1 {
      let perLine = max(1, h2 - h1)
      let extra = max(0, h - h1)
      let lines = 1 + Int(ceil(extra / perLine))
      return max(1, lines)
    }
    // Fallback to ratio by single line height
    return max(1, Int(ceil(h / h1)))
  }
}
