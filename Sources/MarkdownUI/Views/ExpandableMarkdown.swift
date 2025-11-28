import SwiftUI

@available(iOS 15.0, *)
public struct ExpandableMarkdown: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme
    @Environment(\.softBreakMode) private var softBreakMode
    @Environment(\.baseURL) private var baseURL
    @Environment(\.imageBaseURL) private var imageBaseURL

    private let content: MarkdownContent
    private let lineLimit: Int
    private let seeMoreText: String
    private let seeLessText: String

    @State private var expanded = false
    @State private var collapsedHeight: CGFloat = 0

    public init(
        _ content: MarkdownContent,
        lineLimit: Int = 3,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less"
    ) {
        self.content = content
        self.lineLimit = max(1, lineLimit)
        self.seeMoreText = seeMoreText
        self.seeLessText = seeLessText
    }

    public init(
        _ markdown: String,
        lineLimit: Int = 3,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less"
    ) {
        self.init(
            MarkdownContent(markdown), lineLimit: lineLimit, seeMoreText: seeMoreText,
            seeLessText: seeLessText)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExpandableBlockSequence(self.blocks)
                .environment(\.markdownMaxLines, expanded ? nil : self.lineLimit)
                .transition(.move(edge: .top))
                .animation(.easeInOut, value: expanded)

            Button(action: { withAnimation { expanded.toggle() } }) {
                Text(expanded ? seeLessText : seeMoreText)
                    .textStyle(self.theme.link)
                    .textStyleFont()
                    .textStyleForegroundColor()
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var blocks: [BlockNode] {
        self.content.blocks.filterImagesMatching(colorScheme: self.colorScheme)
    }
}
