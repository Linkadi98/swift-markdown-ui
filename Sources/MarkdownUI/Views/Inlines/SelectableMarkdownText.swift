import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct SelectableMarkdownText: UIViewRepresentable {
  let attributedString: AttributedString

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.isEditable = false
    textView.isSelectable = true
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.dataDetectorTypes = [.link]
    return textView
  }

  func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.attributedText = NSAttributedString(attributedString)
  }
}
