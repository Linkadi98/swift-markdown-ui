import AsyncDisplayKit
import MarkdownUI
import SwiftUI
import UIKit

final class SamplePreProcessor: MarkdownTextPreProcessor {
    func preprocess(text: String) -> String {
        return text
    }
}

final class SampleUrlHandler: MarkdownUrlHandler {
    func onReceive(url: URL) -> OpenURLAction.Result {
        print(url)
        return .handled
    }
}

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
    private let heightEpsilon: CGFloat = 0.5

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
                // Texture may measure off-main; force UI/layout mutations to main.
                let apply = {
                    let normalized = ceil(height)
                    guard normalized.isFinite, normalized > 0 else { return }
                    if let prev = self.latestMeasuredHeight,
                        abs(prev - normalized) <= self.heightEpsilon
                    {
                        return
                    }

                    self.latestMeasuredHeight = normalized
                    self.style.preferredSize.height = normalized
                    self.invalidateCalculatedLayout()
                    self.setNeedsLayout()
                    self.onSizeChange?()
                }

                if Thread.isMainThread {
                    apply()
                } else {
                    DispatchQueue.main.async(execute: apply)
                }
            },
            mardownTextPreprocessor: SamplePreProcessor(),
            markdownUrlHandler: SampleUrlHandler()
        )
        markdownView = view
        return view
    }

    private func calculateSize(for constrainedSize: CGSize) -> CGSize {
        let width = constrainedSize.width

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
        let measure = {
            let measured = self.calculateSize(for: constrainedSize)
            self.style.preferredSize = measured
            return measured
        }

        if Thread.isMainThread {
            return measure()
        } else {
            return DispatchQueue.main.sync(execute: measure)
        }
    }
}
