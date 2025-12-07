import MarkdownUI
import SwiftUI

@available(iOS 15.0, *)
struct ExpandableMarkdownDemoView: View {
  @State private var isExpanded: Bool = false
  private let sample = """
    # Expandable Demo

    ## Headings
    ### Subheading Level 3

    ---

    ## Paragraphs & Inline Styles
    This is a long paragraph with **bold**, _italic_, `code`, and a [link](https://example.com) that should be truncated in collapsed mode. Further text to ensure multiple lines for truncation, including another [link](https://apple.com) and more inline styles like ~~strikethrough~~, superscript^TM^, and subscript_{note}.

    *Emphasis* and **Strong**, `inline code`, and automatic URLs: https://swift.org.

    Superscript: E = mc^2^, and subscript: H_{2}O molecule.

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

    ## Code Block
    ```swift
    struct Greeter {
        func greet(name: String) -> String {
            "Hello, Jason!"
        }
    }
    ```

    ## Table
    | Feature | Supported |
    |:-------:|:---------:|
    | Bold    | Yes       |
    | Italic  | Yes       |
    | Code    | Yes       |
    | Links   | Yes       |

    ## Images
    ![Swift Logo](https://swift.org/assets/images/swift.svg)

    Final paragraph to ensure multiple lines for truncation, including another [link](https://apple.com) and more inline styles like ~~strikethrough~~, superscript^test^, and subscript_{H2O}.
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

        ExpandableMarkdown(sample, lineLimit: 5, isExpanded: $isExpanded)
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
