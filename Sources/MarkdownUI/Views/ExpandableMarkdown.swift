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
    private let onTruncationChanged: ((Bool) -> Void)?
    private let showsExpansionButton: Bool
    private let expansionButtonEnabled: Bool
    // If true, the expansion button is only shown when the view is
    // collapsed and the content is truncated.
    private let showExpansionButtonOnlyWhenCollapsedAndTruncated: Bool

    @State private var isContentTruncated: Bool = true
    @State private var expandedContentHeight: CGFloat = 0
    @State public var collapsedHeight: CGFloat = 0
    @State private var internalExpanded = false

    private let markdownBinding: Binding<String>?
    private var externalExpanded: Binding<Bool>?

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
        showsExpansionButton: Bool = true,
        expansionButtonEnabled: Bool = true,
        showExpansionButtonOnlyWhenCollapsedAndTruncated: Bool = true,
        onExpandChange: ((Double) -> Void)? = nil,
        onTruncationChanged: ((Bool) -> Void)? = nil
    ) {
        self.content = content
        self.lineLimit = max(1, lineLimit)
        self.seeMoreText = seeMoreText
        self.seeLessText = seeLessText
        self.externalExpanded = isExpanded
        self.onExpandChange = onExpandChange
        self.onTruncationChanged = onTruncationChanged
        self.markdownBinding = nil
        self.showsExpansionButton = showsExpansionButton
        self.expansionButtonEnabled = expansionButtonEnabled
        self.showExpansionButtonOnlyWhenCollapsedAndTruncated =
            showExpansionButtonOnlyWhenCollapsedAndTruncated
    }

    public init(
        _ markdown: String,
        lineLimit: Int = 5,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        isExpanded: Binding<Bool>? = nil,
        showsExpansionButton: Bool = true,
        expansionButtonEnabled: Bool = true,
        showExpansionButtonOnlyWhenCollapsedAndTruncated: Bool = true,
        onExpandChange: ((Double) -> Void)? = nil,
        onTruncationChanged: ((Bool) -> Void)? = nil
    ) {
        self.init(
            MarkdownContent(markdown),
            lineLimit: lineLimit,
            seeMoreText: seeMoreText,
            seeLessText: seeLessText,
            isExpanded: isExpanded,
            showsExpansionButton: showsExpansionButton,
            expansionButtonEnabled: expansionButtonEnabled,
            showExpansionButtonOnlyWhenCollapsedAndTruncated:
                showExpansionButtonOnlyWhenCollapsedAndTruncated,
            onExpandChange: onExpandChange,
            onTruncationChanged: onTruncationChanged
        )
    }

    /// Initialize with a binding to markdown text for dynamic updates
    public init(
        markdown: Binding<String>,
        lineLimit: Int = 5,
        seeMoreText: String = "...See more",
        seeLessText: String = "See less",
        isExpanded: Binding<Bool>? = nil,
        onExpandChange: ((Double) -> Void)? = nil,
        onTruncationChanged: ((Bool) -> Void)? = nil
    ) {
        self.content = MarkdownContent(markdown.wrappedValue)
        self.lineLimit = max(1, lineLimit)
        self.seeMoreText = seeMoreText
        self.seeLessText = seeLessText
        self.externalExpanded = isExpanded
        self.onExpandChange = onExpandChange
        self.onTruncationChanged = onTruncationChanged
        self.markdownBinding = markdown
        // default expansion button config for this initializer
        self.showsExpansionButton = true
        self.expansionButtonEnabled = true
        self.showExpansionButtonOnlyWhenCollapsedAndTruncated = true
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main content (collapsed/expanded)
            ExpandableBlockSequence(self.blocks)
                .environment(\.markdownMaxLines, expanded ? nil : self.lineLimit)
            // Expansion button: show/hide and enable/disable based on configuration
            // Compute shouldShowButton without negations in the expression for clarity
            let isCollapsed = !expanded
            let shouldShowButton =
                showsExpansionButton
                && (showExpansionButtonOnlyWhenCollapsedAndTruncated
                    ? (isCollapsed && isContentTruncated)
                    : true)
            if shouldShowButton {
                Button(action: {
                    guard expansionButtonEnabled else { return }
                    expanded.toggle()
                }) {
                    Text(expanded ? seeLessText : seeMoreText)
                        .textStyle(self.theme.link)
                        .textStyleFont()
                        .textStyleForegroundColor()
                }
                .buttonStyle(.plain)
                .allowsHitTesting(expansionButtonEnabled)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .animation(nil, value: expanded)
        // Attach collapsed measurement to container to avoid interfering with content layout
        .background(collapsedHeightReader)
        // Hidden probe overlay for full height measurement (non-interfering)
        .overlay(fullHeightProbe, alignment: .topLeading)
        // Remove single reader and rely on dual measurements
        .id(markdownBinding?.wrappedValue ?? "")  // Force refresh when binding changes
    }
    // Measure collapsed height (with line limit)
    private var collapsedHeightReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                let h = proxy.size.height
                collapsedHeight = h
                updateTruncationIfPossible()
                onExpandChange?(h)
            }.onChange(of: proxy.size.height) { newH in
                collapsedHeight = newH
                updateTruncationIfPossible()
                onExpandChange?(newH)
            }
        }
    }

    // Hidden full-height probe that always measures content with no line limit
    private var fullHeightProbe: some View {
        ExpandableBlockSequence(self.blocks)
            .environment(\.markdownMaxLines, nil)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .layoutPriority(-1)
            .overlay(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        let h = proxy.size.height
                        expandedContentHeight = h
                        updateTruncationIfPossible()
                    }.onChange(of: proxy.size.height) { newH in
                        expandedContentHeight = newH
                        updateTruncationIfPossible()
                    }
                }
            )
    }

    private func updateTruncationIfPossible() {
        if expandedContentHeight > 0 && collapsedHeight > 0 {
            let canTruncate = expandedContentHeight > (collapsedHeight + 0.5)
            isContentTruncated = canTruncate
            onTruncationChanged?(canTruncate)
        }
    }

    private var blocks: [BlockNode] {
        self.currentContent.blocks.filterImagesMatching(colorScheme: self.colorScheme)
    }
}
