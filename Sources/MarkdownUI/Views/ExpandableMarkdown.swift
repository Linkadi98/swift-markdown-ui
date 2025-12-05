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
    private let onExpandChange: ((Double) -> Void)?
    private let markdownBinding: Binding<String>?

    @State private var internalExpanded = false
    private var externalExpanded: Binding<Bool>?
    
    @State public var collapsedHeight: CGFloat = 0
    
    private var expanded: Bool {
        get { externalExpanded?.wrappedValue ?? internalExpanded }
        nonmutating set {
            if let binding = externalExpanded {
                binding.wrappedValue = newValue
            } else {
                internalExpanded = newValue
            }
        }
    }
    
    private var currentContent: MarkdownContent {
        if let binding = markdownBinding {
            return MarkdownContent(binding.wrappedValue)
        }
        return content
    }

    public init(
        _ content: MarkdownContent,
        lineLimit: Int = 5,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        isExpanded: Binding<Bool>? = nil,
        onExpandChange: ((Double) -> Void)? = nil
    ) {
        self.content = content
        self.lineLimit = max(1, lineLimit)
        self.seeMoreText = seeMoreText
        self.seeLessText = seeLessText
        self.externalExpanded = isExpanded
        self.onExpandChange = onExpandChange
        self.markdownBinding = nil
    }

    public init(
        _ markdown: String,
        lineLimit: Int = 5,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        isExpanded: Binding<Bool>? = nil,
        onExpandChange: ((Double) -> Void)? = nil
    ) {
        self.init(
            MarkdownContent(markdown),
            lineLimit: lineLimit,
            seeMoreText: seeMoreText,
            seeLessText: seeLessText,
            isExpanded: isExpanded,
            onExpandChange: onExpandChange
        )
    }
    
    /// Initialize with a binding to markdown text for dynamic updates
    public init(
        markdown: Binding<String>,
        lineLimit: Int = 5,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        isExpanded: Binding<Bool>? = nil,
        onExpandChange: ((Double) -> Void)? = nil
    ) {
        self.content = MarkdownContent(markdown.wrappedValue)
        self.lineLimit = max(1, lineLimit)
        self.seeMoreText = seeMoreText
        self.seeLessText = seeLessText
        self.externalExpanded = isExpanded
        self.onExpandChange = onExpandChange
        self.markdownBinding = markdown
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExpandableBlockSequence(self.blocks)
                .environment(\.markdownMaxLines, expanded ? nil : self.lineLimit)

            Button(action: {
                expanded.toggle()
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
        .background(heightReader)
        .id(markdownBinding?.wrappedValue ?? "") // Force refresh when binding changes
    }

    private var heightReader: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            Color.clear
                .onChange(of: h) { newVal in
                    onExpandChange?(newVal)
                }
        }
    }

    private var blocks: [BlockNode] {
        self.currentContent.blocks.filterImagesMatching(colorScheme: self.colorScheme)
    }
}
