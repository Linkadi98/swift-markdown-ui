import SwiftUI

@available(iOS 15.0, *)
class ExpandedStateHolder: ObservableObject {
    @Published var isExpanded: Bool = false
}

@available(iOS 15.0, *)
struct ExpandableMarkdownWrapper: View {
    @ObservedObject var expandedStateHolder: ExpandedStateHolder

    let markdown: String
    let lineLimit: Int
    let seeMoreText: String
    let seeLessText: String
    let showsExpansionButton: Bool
    let expansionButtonEnabled: Bool
    let showExpansionButtonOnlyWhenCollapsedAndTruncated: Bool
    let theme: Theme
    let softBreakMode: SoftBreak.Mode
    let expansionButtonStyle: ExpansionButtonStyle?
    let markdownUrlHandler: MarkdownUrlHandler?
    let onExpandChange: (Double) -> Void
    let onTruncationChanged: (Bool) -> Void

    var body: some View {
        let expandableView = ExpandableMarkdown(
            markdown,
            lineLimit: lineLimit,
            seeMoreText: seeMoreText,
            seeLessText: seeLessText,
            isExpanded: $expandedStateHolder.isExpanded,
            showsExpansionButton: showsExpansionButton,
            expansionButtonEnabled: expansionButtonEnabled,
            showExpansionButtonOnlyWhenCollapsedAndTruncated:
                showExpansionButtonOnlyWhenCollapsedAndTruncated,
            onExpandChange: onExpandChange,
            onTruncationChanged: onTruncationChanged
        )
        .markdownTheme(theme)
        .markdownSoftBreakMode(softBreakMode)

        if let buttonStyle = expansionButtonStyle {
            expandableView
                .expansionButtonStyle(buttonStyle)
                .environment(
                    \.openURL,
                    OpenURLAction { url in
                        if let handler = markdownUrlHandler {
                            return handler.onReceive(url: url)
                        }
                        return .discarded
                    }
                )
        } else {
            expandableView
                .environment(
                    \.openURL,
                    OpenURLAction { url in
                        if let handler = markdownUrlHandler {
                            return handler.onReceive(url: url)
                        }
                        return .discarded
                    }
                )
        }
    }
}

@available(iOS 15.0, *)
public protocol MarkdownTextPreProcessor {
    func preprocess(text: String) -> String
}

@available(iOS 15.0, *)
public protocol MarkdownUrlHandler {
    func onReceive(url: URL) -> OpenURLAction.Result
}

#if canImport(UIKit)
    import UIKit

    @available(iOS 15.0, *)
    public final class MarkdownUIView: UIView {
        private var hosting: UIHostingController<AnyView>!
        private var currentHeight: CGFloat = 0
        private var lastMeasuredWidth: CGFloat = 0
        private var pendingHeight: CGFloat?
        private var isApplyingHeight: Bool = false

        private let heightEpsilon: CGFloat = 0.5
        private var onHeightChange: ((CGFloat) -> Void)? = nil
        private var onTruncationChanged: ((Bool) -> Void)? = nil
        private var preprocessor: MarkdownTextPreProcessor?
        private var markdownUrlHandler: MarkdownUrlHandler?
        private var expandedStateHolder = ExpandedStateHolder()
        private var currentCanTruncate: Bool = false
        private var seeMoreText: String
        private var seeLessText: String

        // Store config for updates
        private var currentMarkdown: String = ""
        private var lineLimit: Int?
        private var theme: Theme = .basic
        private var showsExpansionButton: Bool = true
        private var expansionButtonEnabled: Bool = true
        private var showExpansionButtonOnlyWhenCollapsedAndTruncated: Bool = true
        private var expansionButtonStyle: ExpansionButtonStyle?
        private var softBreakMode: SoftBreak.Mode = .lineBreak  // Default to preserve newlines

        public init(
            markdown: String,
            lineLimit: Int? = nil,
            theme: Theme = .basic,
            showsExpansionButton: Bool = true,
            expansionButtonEnabled: Bool = true,
            showExpansionButtonOnlyWhenCollapsedAndTruncated: Bool = true,
            expansionButtonStyle: ExpansionButtonStyle? = nil,
            softBreakMode: SoftBreak.Mode = .lineBreak,
            onHeightChange: ((CGFloat) -> Void)? = nil,
            onTruncationChanged: ((Bool) -> Void)? = nil,
            mardownTextPreprocessor: MarkdownTextPreProcessor? = nil,
            markdownUrlHandler: MarkdownUrlHandler? = nil,
            seeMoreText: String = "",
            seeLessText: String = ""
        ) {
            self.seeLessText = seeLessText
            self.seeMoreText = seeMoreText

            super.init(frame: .zero)
            self.backgroundColor = .clear
            // Prevent SwiftUI content from briefly drawing outside our bounds
            // while Auto Layout is catching up with intrinsicContentSize changes.
            self.clipsToBounds = true
            self.preprocessor = mardownTextPreprocessor
            self.markdownUrlHandler = markdownUrlHandler
            self.currentMarkdown = markdown
            self.lineLimit = lineLimit
            self.theme = theme
            self.showsExpansionButton = showsExpansionButton
            self.expansionButtonEnabled = expansionButtonEnabled
            self.showExpansionButtonOnlyWhenCollapsedAndTruncated =
                showExpansionButtonOnlyWhenCollapsedAndTruncated
            self.expansionButtonStyle = expansionButtonStyle
            self.softBreakMode = softBreakMode
            self.onHeightChange = onHeightChange
            self.onTruncationChanged = onTruncationChanged

            let view = self.buildView(markdown: markdown)
            self.hosting = UIHostingController(rootView: view)
            self.hosting.view.backgroundColor = .clear
            self.hosting.view.clipsToBounds = true
            self.embed(hosting.view)
        }

        // MARK: - Expand / Collapse controls for UIKit
        public func setExpanded(_ expanded: Bool) {
            expandedStateHolder.isExpanded = expanded
            // Trigger layout update
            self.hosting.view.setNeedsLayout()
            self.hosting.view.layoutIfNeeded()
            let width = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
            let h = sizeThatFitsWidth(width).height
            if h > 0 { updateHeight(h) }
        }

        public func expand() { setExpanded(true) }
        public func collapse() { setExpanded(false) }
        public func toggle() { setExpanded(!expandedStateHolder.isExpanded) }

        /// Updates the markdown text and rebuilds the view
        public func updateMarkdown(_ markdown: String) {
            self.currentMarkdown = markdown
            let view = self.buildView(markdown: markdown)
            self.hosting.rootView = view

            // Trigger layout update
            self.hosting.view.setNeedsLayout()
            self.hosting.view.layoutIfNeeded()

            let width = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
            let h = sizeThatFitsWidth(width).height
            if h > 0 { updateHeight(h) }
        }

        private func buildView(markdown: String) -> AnyView {
            let preprocessedMarkdown: String
            if let preprocessor = self.preprocessor {
                preprocessedMarkdown = preprocessor.preprocess(text: markdown)
            } else {
                preprocessedMarkdown = markdown
            }

            let view: AnyView
            if let lineLimit = self.lineLimit {
                view = AnyView(
                    ExpandableMarkdownWrapper(
                        expandedStateHolder: expandedStateHolder,
                        markdown: preprocessedMarkdown,
                        lineLimit: lineLimit,
                        seeMoreText: seeMoreText,
                        seeLessText: seeLessText,
                        showsExpansionButton: showsExpansionButton,
                        expansionButtonEnabled: expansionButtonEnabled,
                        showExpansionButtonOnlyWhenCollapsedAndTruncated:
                            showExpansionButtonOnlyWhenCollapsedAndTruncated,
                        theme: theme,
                        softBreakMode: softBreakMode,
                        expansionButtonStyle: expansionButtonStyle,
                        markdownUrlHandler: markdownUrlHandler,
                        onExpandChange: { [weak self] newHeight in
                            guard let self else { return }
                            self.updateHeight(CGFloat(newHeight))
                        },
                        onTruncationChanged: { [weak self] canTruncate in
                            guard let self else { return }
                            self.currentCanTruncate = canTruncate
                            self.onTruncationChanged?(canTruncate)
                        }
                    )
                )
            } else {
                view = AnyView(
                    Markdown(preprocessedMarkdown)
                        .markdownTheme(theme)
                        .markdownSoftBreakMode(self.softBreakMode)
                        .environment(
                            \.openURL,
                            OpenURLAction { url in
                                if let handler = self.markdownUrlHandler {
                                    return handler.onReceive(url: url)
                                }
                                return .discarded
                            }
                        ))
            }
            return view
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        private func embed(_ child: UIView) {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)

            // Pin leading, trailing, and top only
            // Let the hosting view determine its own height based on SwiftUI content
            NSLayoutConstraint.activate([
                child.leadingAnchor.constraint(equalTo: leadingAnchor),
                child.trailingAnchor.constraint(equalTo: trailingAnchor),
                child.topAnchor.constraint(equalTo: topAnchor),
                child.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

            // Set content hugging to high so it doesn't stretch
            child.setContentHuggingPriority(.required, for: .vertical)
            child.setContentCompressionResistancePriority(.required, for: .vertical)

            // Initial height from intrinsic content
            let h = sizeThatFitsWidth(
                self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width
            ).height
            if h > 0 { updateHeight(h) }
        }

        private func updateHeight(_ height: CGFloat) {
            let normalized = ceil(height)
            guard normalized.isFinite, normalized > 0 else { return }

            // Avoid feedback loops from tiny fluctuations.
            guard abs(normalized - currentHeight) > heightEpsilon else { return }

            // Apply synchronously to avoid a 1-frame delay where SwiftUI content can
            // render using the expanded layout while the containing UIView still has
            // the old (collapsed) height, causing an overlap + "drop" effect.
            if isApplyingHeight {
                pendingHeight = normalized
                return
            }

            isApplyingHeight = true
            defer {
                isApplyingHeight = false
                if let queued = pendingHeight {
                    pendingHeight = nil
                    if abs(queued - currentHeight) > heightEpsilon {
                        updateHeight(queued)
                    }
                }
            }

            currentHeight = normalized
            UIView.performWithoutAnimation {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
                onHeightChange?(normalized)
            }
        }

        private func getHostingViewPrefersize() -> CGSize {
            hosting.view.systemLayoutSizeFitting(
                UIView.layoutFittingCompressedSize,  // Or .layoutFittingExpandedSize
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )

        }

        public override var intrinsicContentSize: CGSize {
            guard currentHeight > 0 else {
                return super.intrinsicContentSize
            }
            return CGSize(width: UIView.noIntrinsicMetric, height: currentHeight)
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            let width = self.bounds.width > 0 ? self.bounds.width : UIScreen.main.bounds.width

            // Measuring inside layoutSubviews can create a loop when the parent adjusts constraints
            // in response to onHeightChange. Only re-measure when width changes or height unknown.
            let widthChanged = abs(width - lastMeasuredWidth) > heightEpsilon
            guard widthChanged || currentHeight <= 0 else { return }
            lastMeasuredWidth = width

            let h = sizeThatFitsWidth(width).height
            if h > 0 { updateHeight(h) }
        }

        /// Calculates height for a given constrained width using Auto Layout fitting.
        public func sizeThatFitsWidth(_ width: CGFloat) -> CGSize {
            let maxHeight: CGFloat = 2000
            let targetSize = CGSize(width: width, height: maxHeight)
            hosting.view.bounds.size = targetSize
            hosting.view.setNeedsLayout()
            hosting.view.layoutIfNeeded()
            let measured: CGSize
            if #available(iOS 16.0, *) {
                measured = hosting.sizeThatFits(in: targetSize)
            } else {
                measured = hosting.view.systemLayoutSizeFitting(
                    targetSize,
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )
            }
            let h = measured.height > 0 ? measured.height : currentHeight
            return CGSize(width: width, height: ceil(h))
        }

        // MARK: - Observability
        public var isExpanded: Bool { expandedStateHolder.isExpanded }
        public var canTruncate: Bool { currentCanTruncate }

        // MARK: - Expansion Button Style

        /// Update the expansion button style
        public func setExpansionButtonStyle(_ style: ExpansionButtonStyle?) {
            self.expansionButtonStyle = style
            // Rebuild view to apply new style
            self.hosting.rootView = self.buildView(markdown: currentMarkdown)
            self.hosting.view.setNeedsLayout()
            self.hosting.view.layoutIfNeeded()
        }

        /// Convenience method to set expansion button style with individual parameters
        public func setExpansionButtonStyle(
            font: UIFont? = nil,
            foregroundColor: UIColor? = nil,
            backgroundColor: UIColor? = nil,
            cornerRadius: CGFloat = 0,
            padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        ) {
            let style = ExpansionButtonStyle(
                font: font.map { Font(($0 as CTFont)) },
                foregroundColor: foregroundColor.map { Color($0) },
                backgroundColor: backgroundColor.map { Color($0) },
                cornerRadius: cornerRadius,
                padding: EdgeInsets(
                    top: padding.top,
                    leading: padding.left,
                    bottom: padding.bottom,
                    trailing: padding.right
                )
            )
            setExpansionButtonStyle(style)
        }

        // MARK: - Soft Break Mode

        /// Update the soft break mode to control how newlines are rendered
        /// - Parameter mode: `.space` treats newlines as spaces (default Markdown), `.lineBreak` preserves newlines
        public func setSoftBreakMode(_ mode: SoftBreak.Mode) {
            self.softBreakMode = mode
            // Rebuild view to apply new mode
            self.hosting.rootView = self.buildView(markdown: currentMarkdown)
            self.hosting.view.setNeedsLayout()
            self.hosting.view.layoutIfNeeded()
        }
    }
#endif
