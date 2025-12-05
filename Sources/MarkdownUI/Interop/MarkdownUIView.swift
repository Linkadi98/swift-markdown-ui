import SwiftUI

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
    private var onHeightChange: ((CGFloat) -> Void)? = nil
    private var preprocessor: MarkdownTextPreProcessor?
    private var markdownUrlHandler: MarkdownUrlHandler?
    private var isExpandedBinding: Binding<Bool>?
    
    // Store config for updates
    private var currentMarkdown: String = ""
    private var lineLimit: Int?
    private var theme: Theme = .basic
    
    public init(
        markdown: String,
        lineLimit: Int? = nil,
        theme: Theme = .basic,
        isExpanded: Binding<Bool>? = nil,
        onHeightChange: ((CGFloat) -> Void)? = nil,
        mardownTextPreprocessor: MarkdownTextPreProcessor? = nil,
        markdownUrlHandler: MarkdownUrlHandler? = nil
    ) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.preprocessor = mardownTextPreprocessor
        self.markdownUrlHandler = markdownUrlHandler
        self.isExpandedBinding = isExpanded
        self.currentMarkdown = markdown
        self.lineLimit = lineLimit
        self.theme = theme
        self.onHeightChange = onHeightChange
        
        let view = self.buildView(markdown: markdown)
        self.hosting = UIHostingController(rootView: view)
        self.hosting.view.backgroundColor = .clear
        self.embed(hosting.view)
    }
    
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
                ExpandableMarkdown(
                    preprocessedMarkdown, lineLimit: lineLimit,
                    isExpanded: isExpandedBinding,
                    onExpandChange: { [weak self] newHeight in
                        guard let self else { return }
                        self.hosting.view.layoutIfNeeded()
                        self.updateHeight(newHeight)
                    }
                )
                .markdownTheme(theme)
                .environment(
                    \.openURL,
                     OpenURLAction { url in
                         if let handler = self.markdownUrlHandler {
                             return handler.onReceive(url: url)
                         }
                         return .discarded
                     }
                )
            )
        } else {
            view = AnyView(Markdown(preprocessedMarkdown).markdownTheme(theme).markdownTheme(theme)
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
        guard height != currentHeight else { return }
        currentHeight = height
        
        self.invalidateIntrinsicContentSize()
        self.setNeedsLayout()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onHeightChange?(self.currentHeight)
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
}
#endif
