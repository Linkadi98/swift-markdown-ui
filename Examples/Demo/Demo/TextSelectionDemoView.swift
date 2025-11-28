import SwiftUI
import MarkdownUI

@available(iOS 15.0, *)
struct TextSelectionDemoView: View {
    private let sample = """
    # Text Selection Demo
    
    ## Try selecting this text
    
    You can now **select** and _copy_ markdown text including:
    
    - **Bold text**
    - _Italic text_ 
    - `Code snippets`
    - [Links](https://example.com)
    - Superscript^TM^ and subscript_{H2O}
    - ~~Strikethrough text~~
    
    > This blockquote text is also selectable
    
    ```swift
    // Even code blocks are selectable
    func selectableCode() {
        print("Hello, World!")
    }
    ```
    
    | Column 1 | Column 2 |
    |----------|----------|
    | Cell A   | Cell B   |
    | Cell C   | Cell D   |
    
    Long paragraph with multiple lines that demonstrates text selection across line breaks and different formatting styles. You should be able to select across paragraphs and maintain formatting context.
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Text Selection Feature")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Try long-pressing and selecting text in the markdown content below:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Markdown(sample)
                    .markdownTheme(.gitHub)
                    .markdownTextSelection(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Divider()
                
                Text("Expandable Markdown with Selection")
                    .font(.headline)
                
                ExpandableMarkdown(sample, lineLimit: 3)
                    .markdownTheme(.gitHub)
                    .markdownTextSelection(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Text Selection")
    }
}

@available(iOS 15.0, *)
struct TextSelectionDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TextSelectionDemoView()
        }
    }
}