import SwiftUI

// Environment key for custom expansion button style
@available(iOS 15.0, *)
struct ExpansionButtonStyleKey: EnvironmentKey {
    static let defaultValue: ExpansionButtonStyle? = nil
}

@available(iOS 15.0, *)
extension EnvironmentValues {
    var expansionButtonStyle: ExpansionButtonStyle? {
        get { self[ExpansionButtonStyleKey.self] }
        set { self[ExpansionButtonStyleKey.self] = newValue }
    }
}

@available(iOS 15.0, *)
public struct ExpansionButtonStyle {
    public var font: Font?
    public var foregroundColor: Color?
    public var backgroundColor: Color?
    public var cornerRadius: CGFloat
    public var padding: EdgeInsets

    public init(
        font: Font? = nil,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        padding: EdgeInsets = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    ) {
        self.font = font
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
}

@available(iOS 15.0, *)
public struct ExpandableMarkdown: View {
    @Environment(\.colorScheme) public var colorScheme
    @Environment(\.theme) public var theme
    @Environment(\.softBreakMode) public var softBreakMode
    @Environment(\.baseURL) public var baseURL
    @Environment(\.imageBaseURL) public var imageBaseURL
    @Environment(\.expansionButtonStyle) private var expansionButtonStyle

    private let content: MarkdownContent
    private let lineLimit: Int
    private let seeMoreText: String
    private let seeLessText: String
    private let onExpandChange: ((Double) -> Void)?
    private let onTruncationChanged: ((Bool) -> Void)?
    private let showsExpansionButton: Bool
    private let expansionButtonEnabled: Bool
    private let customExpansionButton: ((Bool, () -> Void) -> AnyView)?

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
        self.customExpansionButton = nil
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
        self.customExpansionButton = nil
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
                if let customButton = customExpansionButton {
                    customButton(expanded) {
                        guard expansionButtonEnabled else { return }
                        expanded.toggle()
                    }
                } else {
                    Button(action: {
                        guard expansionButtonEnabled else { return }
                        expanded.toggle()
                    }) {
                        let buttonText = Text(expanded ? seeLessText : seeMoreText)

                        if let style = expansionButtonStyle {
                            buttonText
                                .font(style.font)
                                .foregroundColor(style.foregroundColor)
                                .padding(style.padding)
                                .background(style.backgroundColor)
                                .cornerRadius(style.cornerRadius)
                        } else {
                            buttonText
                                .textStyle(self.theme.link)
                                .textStyleFont()
                                .textStyleForegroundColor()
                        }
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(expansionButtonEnabled)
                }
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

// Public API for styling expansion button
@available(iOS 15.0, *)
extension View {
    /// Apply custom style to the expansion button in ExpandableMarkdown
    /// - Parameter style: The style to apply to expansion buttons
    /// - Returns: A view with the custom expansion button style applied
    public func expansionButtonStyle(_ style: ExpansionButtonStyle) -> some View {
        self.environment(\.expansionButtonStyle, style)
    }

    /// Apply custom style to the expansion button using individual parameters
    public func expansionButtonStyle(
        font: Font? = nil,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        padding: EdgeInsets = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    ) -> some View {
        let style = ExpansionButtonStyle(
            font: font,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            padding: padding
        )
        return self.environment(\.expansionButtonStyle, style)
    }
}

// Extension to make ExpandableMarkdown copyable - REMOVED (not needed with environment approach)
