//
//  TextureMarkdownDemoView.swift
//  Demo
//
//  Created by Minh Ngoc Pham on 3/12/25.
//

import AsyncDisplayKit
import MarkdownUI
import SwiftUI

@available(iOS 15.0, *)
struct TextureMarkdownDemoView: View {
    var body: some View {
        TextureNodeContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

@available(iOS 15.0, *)
struct TextureNodeContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TextureMarkdownViewController {
        return TextureMarkdownViewController()
    }
    
    func updateUIViewController(_ uiViewController: TextureMarkdownViewController, context: Context) {
        // No updates needed
    }
}

@available(iOS 15.0, *)
class TextureMarkdownViewController: ASDKViewController<ASDisplayNode> {
    
    private let tableNode: ASTableNode
    
    private let markdownSamples: [(title: String, content: String)] = [
        (
            title: "Simple Text",
            content: """
      # Hello from Texture + MarkdownUI!
      
      This is a **simple** markdown example integrated with ASDisplayNode.
      """
        ),
        (
            title: "Lists and Formatting",
            content: """
      ## Features
      
      - ✅ **Bold** and *italic* text
      - ✅ Lists and nested items
      - ✅ Code blocks
      - ✅ Dynamic height calculation
      
      > This is a blockquote showing that complex layouts work!
      """
        ),
        (
            title: "Code Block",
            content: """
      ### Swift Code Example
      
      ```swift
      struct ContentView: View {
          var body: some View {
              Text("Hello, World!")
          }
      }
      ```
      
      The height automatically adjusts to the content size.
      """
        ),
        (
            title: "Long Content",
            content: """
      ## Testing Height Calculation
      
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      
      ### Multiple Sections
      
      1. First item with some text
      2. Second item with more text
      3. Third item with even more text
      
      **Bold text** and *italic text* mixed with normal text to test formatting.
      
      | Column 1 | Column 2 | Column 3 |
      |----------|----------|----------|
      | Cell 1   | Cell 2   | Cell 3   |
      | Cell 4   | Cell 5   | Cell 6   |
      
      > A quote at the end to verify vertical spacing works correctly.
      """
        ),
        (
            title: "Minimal Example",
            content: "Just a single line of text."
        ),
    ]
    
    override init() {
        self.tableNode = ASTableNode(style: .plain)
        super.init(node: tableNode)
        
        self.tableNode.dataSource = self
        self.tableNode.delegate = self
        self.tableNode.view.separatorStyle = .singleLine
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Texture + MarkdownUI"
        self.node.backgroundColor = .systemGroupedBackground
    }
}

@available(iOS 15.0, *)
extension TextureMarkdownViewController: ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return markdownSamples.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath)
    -> ASCellNodeBlock
    {
        let sample = markdownSamples[indexPath.row]
        
        return {
            let cellNode = MarkdownCellNode(
                title: sample.title,
                markdown: sample.content
            )
            return cellNode
        }
    }
}

@available(iOS 15.0, *)
extension TextureMarkdownViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Cell Node

@available(iOS 15.0, *)
class MarkdownCellNode: ASCellNode {
    private let titleNode: ASTextNode
    private let markdownNode: MarkdownDisplayNode
    private let separatorNode: ASDisplayNode
    
    init(title: String, markdown: String) {
        self.titleNode = ASTextNode()
        self.markdownNode = MarkdownDisplayNode(markdown: markdown, theme: .gitHub)
        self.separatorNode = ASDisplayNode()
        
        super.init()
        
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .systemBackground
        
        // Configure title
        self.titleNode.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
            ]
        )
        
        // Configure separator
        self.separatorNode.backgroundColor = .separator
        self.separatorNode.style.height = ASDimension(unit: .points, value: 1)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        // Title at top
        let titleInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 4, right: 16),
            child: titleNode
        )
        
        // Markdown content
        markdownNode.style.width = ASDimension(unit: .points, value: constrainedSize.max.width)
        
        // Separator at bottom
        separatorNode.style.width = ASDimension(unit: .fraction, value: 1.0)
        
        let separatorInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0),
            child: separatorNode
        )
        
        // Stack vertically
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .stretch,
            children: [titleInset, markdownNode, separatorInset]
        )
        
        return stack
    }
}

@available(iOS 15.0, *)
struct TextureMarkdownDemoView_Previews: PreviewProvider {
    static var previews: some View {
        TextureMarkdownDemoView()
    }
}
