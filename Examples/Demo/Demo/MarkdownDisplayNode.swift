import AsyncDisplayKit
import MarkdownUI
import SwiftUI

/// ASDisplayNode wrapper for MarkdownUI SwiftUI view
/// Demonstrates automatic height calculation from SwiftUI content
@available(iOS 15.0, *)
class MarkdownDisplayNode: ASDisplayNode {
  private let markdownContent: MarkdownContent
  private let theme: Theme
  private var hostingController: UIHostingController<AnyView>?

  init(markdown: String, theme: Theme = .gitHub) {
    self.markdownContent = MarkdownContent(markdown)
    self.theme = theme
    super.init()

    self.automaticallyManagesSubnodes = false
    self.backgroundColor = .systemBackground
  }

  private func ensureHostingController() -> UIHostingController<AnyView> {
    if let existing = hostingController {
      return existing
    }

    // Must create SwiftUI view on main thread
    assert(Thread.isMainThread, "SwiftUI must be initialized on main thread")

    let markdownView = Markdown(self.markdownContent)
      .markdownTheme(self.theme)
      .padding()

    let hosting = UIHostingController(rootView: AnyView(markdownView))
    hosting.view.backgroundColor = .clear
    hostingController = hosting
    return hosting
  }

  private func calculateSize(for constrainedSize: CGSize) -> CGSize {
    let hosting = ensureHostingController()
    let targetSize = CGSize(
      width: constrainedSize.width,
      height: UIView.layoutFittingCompressedSize.height
    )

    let calculatedSize = hosting.view.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )

    return CGSize(
      width: constrainedSize.width,
      height: max(calculatedSize.height, 44)
    )
  }

  override func didLoad() {
    super.didLoad()

    // Add to view hierarchy on main thread
    let hosting = ensureHostingController()
    self.view.addSubview(hosting.view)
  }

  override func layout() {
    super.layout()

    // Manually layout the hosting controller's view to match our calculated size
    hostingController?.view.frame = self.bounds
  }

  override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
    // Ensure we're on main thread for SwiftUI
    if Thread.isMainThread {
      return calculateSize(for: constrainedSize)
    } else {
      // If called from background thread, dispatch to main and wait
      return DispatchQueue.main.sync {
        calculateSize(for: constrainedSize)
      }
    }
  }
}
