import MarkdownUI
import SwiftUI

@available(iOS 15.0, *)
struct ExpandableMarkdownDemoView: View {
    @State private var isExpanded: Bool = false
    private let sample = """
    # Item three with multiple lines to check 

    ## Headings wrapping 
    Bulletin: 
    - First item in a list First item in a list First item in a list
    - Second item.
    - Third item


    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Button("Expand") { isExpanded = true }
                    Button("Collapse") { isExpanded = false }
                    Text(isExpanded ? "Expanded" : "Collapsed")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                ExpandableMarkdown(sample,
                                   lineLimit: 6,
                                   isExpanded: $isExpanded,
                                   expansionButtonEnabled: false,
                                   showExpansionButtonOnlyWhenCollapsedAndTruncated: true,
                                   onTruncationChanged: { canBeTruncated in
                    print("can be truncated: \(canBeTruncated)")
                })
                .markdownTheme(.gitHub)
            }
            .padding()
        }
    }
}

@available(iOS 15.0, *)
struct ExpandableMarkdownDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableMarkdownDemoView()
            .previewLayout(.sizeThatFits)
    }
}
