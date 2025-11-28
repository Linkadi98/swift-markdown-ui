import SwiftUI
#if canImport(UIKit)
import UIKit

@available(iOS 15.0, *)
public final class MarkdownUIView: UIView {
  private let hosting: UIHostingController<AnyView>

  public init(markdown: String,
              lineLimit: Int? = nil,
              theme: Theme = .basic) {
    let view: AnyView
    if let lineLimit {
      view = AnyView(ExpandableMarkdown(markdown, lineLimit: lineLimit).markdownTheme(theme))
    } else {
      view = AnyView(Markdown(markdown).markdownTheme(theme))
    }
    self.hosting = UIHostingController(rootView: view)
    super.init(frame: .zero)
    self.backgroundColor = .clear
    self.hosting.view.backgroundColor = .clear
    self.embed(hosting.view)
  }

  public init(content: MarkdownContent,
              lineLimit: Int? = nil,
              theme: Theme = .basic) {
    let view: AnyView
    if let lineLimit {
      view = AnyView(ExpandableMarkdown(content, lineLimit: lineLimit).markdownTheme(theme))
    } else {
      view = AnyView(Markdown(content).markdownTheme(theme))
    }
    self.hosting = UIHostingController(rootView: view)
    super.init(frame: .zero)
    self.backgroundColor = .clear
    self.hosting.view.backgroundColor = .clear
    self.embed(hosting.view)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func embed(_ child: UIView) {
    child.translatesAutoresizingMaskIntoConstraints = false
    addSubview(child)
    NSLayoutConstraint.activate([
      child.leadingAnchor.constraint(equalTo: leadingAnchor),
      child.trailingAnchor.constraint(equalTo: trailingAnchor),
      child.topAnchor.constraint(equalTo: topAnchor),
      child.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }

  /// Calculates height for a given constrained width.
  public func sizeThatFitsWidth(_ width: CGFloat) -> CGSize {
    let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
    let size = hosting.sizeThatFits(in: targetSize)
    return CGSize(width: width, height: ceil(size.height))
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    hosting.sizeThatFits(in: size)
  }
}
#endif
