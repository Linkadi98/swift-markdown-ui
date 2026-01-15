import SwiftUI

@available(iOS 15.0, *)
struct HeadingView: View {
  @Environment(\.theme.headings) private var headings
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownBlockIndex) private var blockIndex

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
      InlineText(self.content)
        .lineLimit(self.remainingLines >= 1000 ? nil : self.remainingLines)
        .truncationMode(.tail)
        .allowsTightening(true)
    }
  }
}
