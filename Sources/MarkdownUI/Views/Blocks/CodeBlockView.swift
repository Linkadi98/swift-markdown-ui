import SwiftUI

@available(iOS 15.0, *)
struct CodeBlockView: View {
  @Environment(\.theme.codeBlock) private var codeBlock
  @Environment(\.codeSyntaxHighlighter) private var codeSyntaxHighlighter
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownBlockIndex) private var blockIndex
  @State private var totalHeight: CGFloat = 0
  @State private var singleLineHeight: CGFloat = 0
  @State private var twoLineHeight: CGFloat = 0

  private let fenceInfo: String?
  private let content: String

  init(fenceInfo: String?, content: String) {
    self.fenceInfo = fenceInfo
    self.content = content.hasSuffix("\n") ? String(content.dropLast()) : content
  }

  var body: some View {
    self.codeBlock.makeBody(
      configuration: .init(
        language: self.fenceInfo,
        content: self.content,
        label: .init(self.measuredLabel)
      )
    )
  }

  @ViewBuilder private var measuredLabel: some View {
    TextStyleAttributesReader { _ in
      ZStack(alignment: .topLeading) {
        self.label
          .lineLimit(self.remainingLines >= 1000 ? nil : self.remainingLines)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { totalHeight = proxy.size.height }
                .onChange(of: proxy.size.height) { totalHeight = $0 }
            }
          )
        self.label
          .lineLimit(1)
          .opacity(0.001)
          .accessibilityHidden(true)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { singleLineHeight = max(1, proxy.size.height) }
                .onChange(of: proxy.size.height) { singleLineHeight = max(1, $0) }
            }
          )
        self.label
          .lineLimit(2)
          .opacity(0.001)
          .accessibilityHidden(true)
          .background(
            GeometryReader { proxy in
              Color.clear.onAppear { twoLineHeight = max(1, proxy.size.height) }
                .onChange(of: proxy.size.height) { twoLineHeight = max(1, $0) }
            }
          )
      }
      .background(
        Group {
          if self.remainingLines >= 1000 {
            Color.clear.preference(
              key: BlockLinesPreferenceKey.self,
              value: [self.blockIndex: self.computeUsedLines()]
            )
          } else {
            Color.clear.preference(key: BlockLinesPreferenceKey.self, value: [:])
          }
        }
      )
    }
  }

  private var label: some View {
    self.codeSyntaxHighlighter.highlightCode(self.content, language: self.fenceInfo)
      .textStyleFont()
      .textStyleForegroundColor()
  }

  private func estimateUsedLines(proxy: GeometryProxy) -> Int {
    #if canImport(UIKit)
      // Approximate using monospaced or body line height
      let lh = UIFont.preferredFont(forTextStyle: .body).lineHeight
    #else
      let lh: CGFloat = 20
    #endif
    let h = proxy.size.height
    guard lh > 0 else { return 0 }
    return max(1, Int(ceil(h / lh)))
  }

  private func computeUsedLines() -> Int {
    let h = totalHeight
    let h1 = singleLineHeight
    let h2 = twoLineHeight
    guard h > 0, h1 > 0 else { return 1 }
    if h2 > h1 {
      let perLine = max(1, h2 - h1)
      let extra = max(0, h - h1)
      let lines = 1 + Int(ceil(extra / perLine))
      return max(1, lines)
    }
    return max(1, Int(ceil(h / h1)))
  }
}
