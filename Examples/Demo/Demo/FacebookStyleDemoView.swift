import AsyncDisplayKit
import MarkdownUI
import SwiftUI

/// Demo view for Facebook-style posts with ExpandableMarkdown
@available(iOS 15.0, *)
struct FacebookStyleDemoView: View {
    var body: some View {
        FacebookStyleContainer()
            .navigationTitle("Facebook Style Posts")
            .edgesIgnoringSafeArea(.all)
    }
}

@available(iOS 15.0, *)
struct FacebookStyleContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> FacebookStyleViewController {
        return FacebookStyleViewController()
    }

    func updateUIViewController(_ uiViewController: FacebookStyleViewController, context: Context) {
        // No updates needed
    }
}

@available(iOS 15.0, *)
class FacebookStyleViewController: ASDKViewController<ASDisplayNode> {

    private let tableNode: ASTableNode
    private let posts: [FacebookPost] = FacebookPost.samples

    override init() {
        self.tableNode = ASTableNode(style: .plain)

        let containerNode = ASDisplayNode()
        containerNode.automaticallyManagesSubnodes = true
        containerNode.backgroundColor = .systemGroupedBackground
        containerNode.layoutSpecBlock = { [weak tableNode] _, _ in
            guard let tableNode = tableNode else { return ASLayoutSpec() }
            return ASWrapperLayoutSpec(layoutElement: tableNode)
        }

        super.init(node: containerNode)

        self.tableNode.delegate = self
        self.tableNode.dataSource = self
        self.tableNode.backgroundColor = .systemGroupedBackground
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Facebook Style Posts"
    }
}

// MARK: - ASTableDataSource
@available(iOS 15.0, *)
extension FacebookStyleViewController: ASTableDataSource {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath)
        -> ASCellNodeBlock
    {
        let post = posts[indexPath.row]

        return {
            return FacebookPostNode(post: post)
        }
    }
}

// MARK: - ASTableDelegate
@available(iOS 15.0, *)
extension FacebookStyleViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
    }

    // Ensure rows are measured with the correct width (accounting for safe areas)
    func tableNode(_ tableNode: ASTableNode, constrainedSizeForRowAt indexPath: IndexPath)
        -> ASSizeRange
    {
        let horizontalInsets: CGFloat =
            tableNode.view.adjustedContentInset.left + tableNode.view.adjustedContentInset.right
        let safeWidth = tableNode.view.bounds.width - horizontalInsets
        let minSize = CGSize(width: safeWidth, height: 0)
        let maxSize = CGSize(width: safeWidth, height: CGFloat.greatestFiniteMagnitude)

        print("📐 constrainedSizeForRowAt [\(indexPath.row)]: width=\(safeWidth)")

        return ASSizeRange(min: minSize, max: maxSize)
    }

    // Add spacing between posts
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        return view
    }
}

// MARK: - Preview
@available(iOS 15.0, *)
struct FacebookStyleDemoView_Previews: PreviewProvider {
    static var previews: some View {
        FacebookStyleDemoView()
    }
}
