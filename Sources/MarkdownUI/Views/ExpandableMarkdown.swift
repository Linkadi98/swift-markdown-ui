import SwiftUI

@available(iOS 15.0, *)
public struct ExpandableMarkdown: View {
    @Environment(\.colorScheme) public var colorScheme
    @Environment(\.theme) public var theme
    @Environment(\.softBreakMode) public var softBreakMode
    @Environment(\.baseURL) public var baseURL
    @Environment(\.imageBaseURL) public var imageBaseURL
    
    private let content: MarkdownContent
    private let lineLimit: Int
    private let seeMoreText: String
    private let seeLessText: String
    private let onExpandChange: (() -> Void)?
    
    @State public var expanded = false
    @State public var collapsedHeight: CGFloat = 0
    
    public init(
        _ content: MarkdownContent,
        lineLimit: Int = 3,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        onExpandChange: (() -> Void)? = nil
    ) {
        self.content = content
        self.lineLimit = max(1, lineLimit)
        self.seeMoreText = seeMoreText
        self.seeLessText = seeLessText
        self.onExpandChange = onExpandChange
    }
    
    public init(
        _ markdown: String,
        lineLimit: Int = 3,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        onExpandChange: (() -> Void)? = nil
    ) {
        self.init(
            MarkdownContent(markdown),
            lineLimit: lineLimit,
            seeMoreText: seeMoreText,
            seeLessText: seeLessText,
            onExpandChange: onExpandChange
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExpandableBlockSequence(self.blocks)
                .environment(\.markdownMaxLines, expanded ? nil : self.lineLimit)
            Button(action: {
                expanded.toggle()
                onExpandChange?()
            }) {
                Text(expanded ? seeLessText : seeMoreText)
                    .textStyle(self.theme.link)
                    .textStyleFont()
                    .textStyleForegroundColor()
            }
            .buttonStyle(.plain)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .animation(nil, value: expanded)
    }
    
    private var blocks: [BlockNode] {
        self.content.blocks.filterImagesMatching(colorScheme: self.colorScheme)
    }
}
