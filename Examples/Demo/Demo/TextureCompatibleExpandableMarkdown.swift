import MarkdownUI
import SwiftUI

/// Custom ExpandableMarkdown compatible with Texture
/// Has exposed @State so we can read expanded state from outside
@available(iOS 15.0, *)
struct TextureCompatibleExpandableMarkdown: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.theme) private var theme

  private let content: MarkdownContent
  private let lineLimit: Int
  private let seeMoreText: String
  private let seeLessText: String

  // Exposed state that can be read from Texture
  @Binding var isExpanded: Bool

  // Callback when expand state changes
  var onExpandChange: ((Bool) -> Void)?

  init(
    _ markdown: String,
    lineLimit: Int = 3,
    isExpanded: Binding<Bool>,
    seeMoreText: String = "...See more",
    seeLessText: String = "See less",
    onExpandChange: ((Bool) -> Void)? = nil
  ) {
    self.content = MarkdownContent(markdown)
    self.lineLimit = max(1, lineLimit)
    self.seeMoreText = seeMoreText
    self.seeLessText = seeLessText
    self._isExpanded = isExpanded
    self.onExpandChange = onExpandChange
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Use regular Markdown with lineLimit based on exposed state
      Markdown(content)
        .markdownTheme(theme)
        .lineLimit(isExpanded ? nil : lineLimit)

      Button(action: {
        isExpanded.toggle()
        onExpandChange?(isExpanded)
      }) {
        Text(isExpanded ? seeLessText : seeMoreText)
          .textStyle(theme.link)
          .textStyleFont()
          .textStyleForegroundColor()
      }
      .buttonStyle(.plain)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var blocks: [BlockNode] {
    self.content.blocks.filterImagesMatching(colorScheme: self.colorScheme)
  }
}
