import SwiftUI

@available(iOS 15.0, *)
struct ParagraphView: View {
  @Environment(\.theme.paragraph) private var paragraph
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownBlockIndex) private var blockIndex
  @State private var totalHeight: CGFloat = 0
  @State private var singleLineHeight: CGFloat = 0
  @State private var twoLineHeight: CGFloat = 0

  private let content: [InlineNode]

  init(content: String) {
    self.init(
      content: [
        .text(content.hasSuffix("\n") ? String(content.dropLast()) : content)
      ]
    )
  }

  init(content: [InlineNode]) {
    self.content = content
  }

  var body: some View {
    self.paragraph.makeBody(
      configuration: .init(
        label: .init(self.measuredLabel),
        content: .init(block: .paragraph(content: self.content))
      )
    )
  }

  @ViewBuilder private var label: some View {
    if let imageView = ImageView(content) {
      imageView
    } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *),
      let imageFlow = ImageFlow(content)
    {
      imageFlow
    } else {
      InlineText(content)
    }
  }

  // Label wrapped to measure used lines and respect remaining line budget
  @ViewBuilder private var measuredLabel: some View {
    TextStyleAttributesReader { _ in
      ZStack(alignment: .topLeading) {
        // Actual render honoring the budget
        self.label
          .lineLimit(self.remainingLines >= 1000 ? nil : self.remainingLines)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { totalHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { totalHeight = $0 }
            }
          )
        // Hidden one-line probe to measure single-line height under same style
        self.label
          .lineLimit(1)
          .opacity(0.001)
          .accessibilityHidden(true)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { singleLineHeight = max(1, proxy.size.height) }
                .onChange(of: proxy.size.height) { singleLineHeight = max(1, $0) }
            }
          )

        // Hidden two-line probe to compute incremental per-line height
        self.label
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
    // Fallback: divide by body line height approximation
    #if canImport(UIKit)
      let lh = UIFont.preferredFont(forTextStyle: .body).lineHeight
    #else
      let lh: CGFloat = 20
    #endif
    let h = proxy.size.height
    guard lh > 0 else { return 0 }
    return max(1, Int(ceil(h / lh)))
  }

  private func computeUsedLines() -> Int {
    let h = totalHeight
    let h1 = singleLineHeight
    let h2 = twoLineHeight
    guard h > 0 else { return 1 }
    if h2 > h1, h1 >= 8 {
      let perLine = max(1, h2 - h1)
      let extra = max(0, h - h1)
      let lines = 1 + Int(ceil(extra / perLine))
      return max(1, lines)
    }
    if h1 >= 8 {
      return max(1, Int(ceil(h / h1)))
    }
    // Final fallback: use .body line height
    #if canImport(UIKit)
      let lh = UIFont.preferredFont(forTextStyle: .body).lineHeight
      guard lh > 0 else { return 1 }
      return max(1, Int(ceil(h / lh)))
    #else
      return max(1, Int(ceil(h / 20)))
    #endif
  }
}
