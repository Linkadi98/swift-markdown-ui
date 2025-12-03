import AsyncDisplayKit
import UIKit

/// Facebook-style post layout using Texture
/// Header: Avatar + Name + Time
/// Content: ExpandableMarkdown
/// Footer: Like/Comment/Share buttons
@available(iOS 15.0, *)
class FacebookPostNode: ASCellNode {

  // Header nodes
  private let avatarNode: ASImageNode
  private let nameNode: ASTextNode
  private let timeNode: ASTextNode

  // Content
  private let markdownNode: ExpandableMarkdownDisplayNode
  private var isReloadingRow = false

  // Footer nodes
  private let separatorNode: ASDisplayNode
  private let likeButtonNode: ASButtonNode
  private let commentButtonNode: ASButtonNode
  private let shareButtonNode: ASButtonNode

  private let post: FacebookPost

  init(post: FacebookPost) {
    self.post = post

    // Initialize header
    self.avatarNode = ASImageNode()
    self.nameNode = ASTextNode()
    self.timeNode = ASTextNode()

    // Initialize content
    self.markdownNode = ExpandableMarkdownDisplayNode(
      markdown: post.content,
      lineLimit: 3,
      theme: .gitHub
    )

    // Initialize footer
    self.separatorNode = ASDisplayNode()
    self.likeButtonNode = ASButtonNode()
    self.commentButtonNode = ASButtonNode()
    self.shareButtonNode = ASButtonNode()

    super.init()

    self.automaticallyManagesSubnodes = true
    self.backgroundColor = .systemBackground

    // Wire up size change callback to relayout cell
    self.markdownNode.onSizeChange = { [weak self] in
      guard let self = self else { return }

      print("🔄 FacebookPostNode: markdownNode size changed")

      // Invalidate our calculated size
      self.invalidateCalculatedLayout()

      // Find the closest table node and trigger relayout
      DispatchQueue.main.async {
        // Try to find the ASTableNode
        var currentNode: ASDisplayNode? = self
        while let node = currentNode {
          if let tableNode = node as? ASTableNode {
            print("📱 Found ASTableNode, triggering beginUpdates/endUpdates")
            tableNode.view.beginUpdates()
            tableNode.view.endUpdates()
            return
          }
          currentNode = node.supernode
        }

        // Fallback: find UITableView
        var currentView: UIView? = self.view
        while let view = currentView {
          if let tableView = view as? UITableView {
            print("📱 Found UITableView, triggering beginUpdates/endUpdates")
            tableView.beginUpdates()
            tableView.endUpdates()
            return
          }
          currentView = view.superview
        }

        print("⚠️ Could not find table view to update")
      }
    }

    setupNodes()
  }

  private func setupNodes() {
    // Configure avatar
    avatarNode.style.preferredSize = CGSize(width: 40, height: 40)
    avatarNode.cornerRadius = 20
    avatarNode.backgroundColor = .systemBlue
    avatarNode.contentMode = .scaleAspectFill
    avatarNode.clipsToBounds = true

    // Configure name
    nameNode.attributedText = NSAttributedString(
      string: post.authorName,
      attributes: [
        .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
        .foregroundColor: UIColor.label,
      ]
    )

    // Configure time
    timeNode.attributedText = NSAttributedString(
      string: post.timeAgo,
      attributes: [
        .font: UIFont.systemFont(ofSize: 13),
        .foregroundColor: UIColor.secondaryLabel,
      ]
    )

    // Configure separator
    separatorNode.backgroundColor = .separator
    separatorNode.style.height = ASDimension(unit: .points, value: 0.5)

    // Configure buttons
    configureButton(likeButtonNode, title: "👍 Like")
    configureButton(commentButtonNode, title: "💬 Comment")
    configureButton(shareButtonNode, title: "↗️ Share")
  }

  private func configureButton(_ button: ASButtonNode, title: String) {
    button.setTitle(title, with: .systemFont(ofSize: 14), with: .secondaryLabel, for: .normal)
    button.contentHorizontalAlignment = .middle
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    // Header layout (avatar + name/time stack)
    let nameTimeStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 2,
      justifyContent: .center,
      alignItems: .start,
      children: [nameNode, timeNode]
    )

    let headerStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 12,
      justifyContent: .start,
      alignItems: .center,
      children: [avatarNode, nameTimeStack]
    )

    let headerInset = ASInsetLayoutSpec(
      insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
      child: headerStack
    )

    // Respect measured size: avoid flexing
    markdownNode.style.flexGrow = 0
    markdownNode.style.flexShrink = 0

    // Content (markdown)
    let contentInset = ASInsetLayoutSpec(
      insets: UIEdgeInsets(top: 0, left: 12, bottom: 8, right: 12),
      child: markdownNode
    )

    // Footer buttons
    let buttonsStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 0,
      justifyContent: .spaceAround,
      alignItems: .center,
      children: [likeButtonNode, commentButtonNode, shareButtonNode]
    )

    buttonsStack.style.height = ASDimension(unit: .points, value: 44)

    let footerInset = ASInsetLayoutSpec(
      insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
      child: buttonsStack
    )

    // Main vertical stack
    let mainStack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .start,
      alignItems: .stretch,
      children: [
        headerInset,
        contentInset,
        separatorNode,
        footerInset,
      ]
    )

    // Add margin around the entire post for separation
    let marginInset = ASInsetLayoutSpec(
      insets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0),
      child: mainStack
    )

    return marginInset
  }
}

/// Model for Facebook-style post
struct FacebookPost {
  let authorName: String
  let timeAgo: String
  let content: String

  static let samples: [FacebookPost] = [
    FacebookPost(
      authorName: "John Doe",
      timeAgo: "2h",
      content: """
        # Expandable Demo

        # Excited to share my latest project! 🚀

        I've been working on integrating **MarkdownUI** with **Texture/AsyncDisplayKit** and the results are amazing!

        ## Key Features:
        - ✅ Dynamic height calculation
        - ✅ Smooth expand/collapse animations
        - ✅ Off-main-thread rendering
        - ✅ Full markdown support

        Check it out and let me know what you think! 👇
        ## Table
            | Feature | Supported |
            |:-------:|:---------:|
            | Bold    | Yes       |
            | Italic  | Yes       |
            | Code    | Yes       |
            | Links   | Yes       |
        
        ## Lists
        - Item one with **bold** and `code`
        - Item two with a [link](https://developer.apple.com)
        - Item three with multiple lines to check wrapping behavior in collapsed mode. This line should continue to demonstrate truncation.

        1. Ordered item one
        2. Ordered item two
        3. Ordered item three

        - [ ] Task unchecked item
        - [x] Task checked item with ~~strikethrough~~

        > Blockquote: "Simplicity is the ultimate sophistication." — Leonardo da Vinci
        
        """
    )
  ]
}
