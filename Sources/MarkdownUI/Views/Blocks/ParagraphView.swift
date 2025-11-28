import SwiftUI

@available(iOS 15.0, *)
struct ParagraphView: View {
  @Environment(\.theme.paragraph) private var paragraph
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownBlockIndex) private var blockIndex

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
      // Render inline text and apply lineLimit from environment
      self.label
        .lineLimit(self.remainingLines >= 1000 ? nil : self.remainingLines)
        .background(
          GeometryReader { proxy in
            // Report total lines for this block (unbounded by budget) keyed by block index
            Color.clear.preference(
              key: BlockLinesPreferenceKey.self,
              value: [self.blockIndex: self.estimateUsedLines(proxy: proxy)]
            )
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
}
