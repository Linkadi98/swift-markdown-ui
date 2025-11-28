import Foundation

#if canImport(Texture)
import Texture
#elseif canImport(AsyncDisplayKit)
import AsyncDisplayKit
typealias TextureNode = ASDisplayNode
#endif

#if canImport(Texture) || canImport(AsyncDisplayKit)
import UIKit
import SwiftUI

/// A Texture/ASDK node that hosts Markdown content via UIHostingController.
@available(iOS 15.0, *)
final class TextureMarkdownNode: TextureNode {
  private var hostingController: UIHostingController<AnyView>?
  private let markdown: String
  private let lineLimit: Int?

  init(markdown: String, lineLimit: Int? = 3) {
    self.markdown = markdown
    self.lineLimit = lineLimit
    super.init()
    self.automaticallyManagesSubnodes = false
  }

  override func didLoad() {
    super.didLoad()
    let view: AnyView
    if let lineLimit { view = AnyView(ExpandableMarkdown(markdown, lineLimit: lineLimit)) }
    else { view = AnyView(Markdown(markdown)) }
    let hosting = UIHostingController(rootView: view)
    hosting.view.backgroundColor = .clear
    self.hostingController = hosting
    guard let v = hosting.view else { return }
    self.view.addSubview(v)
    v.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      v.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
      v.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      v.topAnchor.constraint(equalTo: self.view.topAnchor),
      v.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
    ])
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    // Let AutoLayout constraints drive size; Texture will size to the node's bounds.
    return ASWrapperLayoutSpec(wrapper: self) // Minimal wrapper
  }
}

#endif
