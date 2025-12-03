import AsyncDisplayKit
import MarkdownUI
import SwiftUI
import UIKit

/// ASDisplayNode wrapper for ExpandableMarkdown SwiftUI view
/// Uses intrinsic height from MarkdownUIView via onHeightChange
@available(iOS 15.0, *)
class ExpandableMarkdownDisplayNode: ASDisplayNode {
    private let markdown: String
    private let lineLimit: Int
    private let theme: Theme
    private var markdownView: MarkdownUIView?
    private var latestMeasuredHeight: CGFloat?
    private var isCurrentlyExpanded = false
    
    var onSizeChange: (() -> Void)?
    
    init(markdown: String, lineLimit: Int = 3, theme: Theme = .gitHub) {
        self.markdown = markdown
        self.lineLimit = lineLimit
        self.theme = theme
        super.init()
        
        self.automaticallyManagesSubnodes = false
        self.backgroundColor = .systemBackground
    }
    
    @discardableResult
    private func ensureMarkdownView() -> MarkdownUIView {
        if let existing = markdownView { return existing }
        
        assert(Thread.isMainThread, "SwiftUI must be initialized on main thread")
        
        let view = MarkdownUIView(
            markdown: markdown,
            lineLimit: lineLimit,
            theme: theme,
            onHeightChange: { [weak self] height in
                guard let self = self else { return }
                print("New height markdown display node: \(height)")
                self.style.preferredSize.height = height
                self.latestMeasuredHeight = height
                self.setNeedsLayout()
            }
        )
        markdownView = view
        return view
    }
    
    private func calculateSize(for constrainedSize: CGSize) -> CGSize {
        let width = constrainedSize.width
        ensureMarkdownView()
        
        var height = latestMeasuredHeight
        if let mView = markdownView {
            height = mView.sizeThatFitsWidth(width).height
        }
        
        return CGSize(width: width, height: height ?? 0)
    }
    
    override func didLoad() {
        super.didLoad()
        let mView = ensureMarkdownView()
        self.view.addSubview(mView)
        mView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    override func layout() {
        super.layout()
        if let mView = markdownView {
            mView.frame = self.bounds
            print("🖼️ ExpandableMarkdownDisplayNode layout - frame: \(self.bounds)")
        }
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let measured: CGSize
        if Thread.isMainThread {
            measured = calculateSize(for: constrainedSize)
        } else {
            measured = DispatchQueue.main.sync { calculateSize(for: constrainedSize) }
        }
        self.style.preferredSize = measured
        return measured
    }
}
