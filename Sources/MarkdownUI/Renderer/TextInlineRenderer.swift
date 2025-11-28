import SwiftUI

@available(iOS 15.0, *)
extension Sequence where Element == InlineNode {
  func renderText(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    images: [String: Image],
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) -> Text {
    var renderer = TextInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      images: images,
      softBreakMode: softBreakMode,
      attributes: attributes
    )
    renderer.render(self)
    return renderer.result
  }
}

@available(iOS 15.0, *)
private struct TextInlineRenderer {
  var result = Text("")

  private let baseURL: URL?
  private let textStyles: InlineTextStyles
  private let images: [String: Image]
  private let softBreakMode: SoftBreak.Mode
  private let attributes: AttributeContainer
  private var shouldSkipNextWhitespace = false

  init(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    images: [String: Image],
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) {
    self.baseURL = baseURL
    self.textStyles = textStyles
    self.images = images
    self.softBreakMode = softBreakMode
    self.attributes = attributes
  }

  mutating func render<S: Sequence>(_ inlines: S) where S.Element == InlineNode {
    for inline in inlines {
      self.render(inline)
    }
  }

  private mutating func render(_ inline: InlineNode) {
    switch inline {
    case .text(let content):
      self.renderText(content)
    case .softBreak:
      self.renderSoftBreak()
    case .html(let content):
      self.renderHTML(content)
    case .image(let source, _):
      self.renderImage(source)
    default:
      self.defaultRender(inline)
    }
  }

  private mutating func renderText(_ text: String) {
    var text = text

    if self.shouldSkipNextWhitespace {
      self.shouldSkipNextWhitespace = false
      text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }

    // Simple check to avoid conflicts with strikethrough - just do basic parsing

    // Custom: lightweight parse for ^superscript^ and ~subscript~
    // Use different delimiters to avoid conflict: ^...^ for superscript, _{...} for subscript
    var cursor = text.startIndex
    func appendNormal(_ s: Substring) {
      guard !s.isEmpty else { return }
      self.defaultRender(.text(String(s)))
    }

    while cursor < text.endIndex {
      // Look for ^...^ superscript
      if let caretStart = text[cursor...].firstIndex(of: "^") {
        let afterCaret = text.index(after: caretStart)
        if afterCaret < text.endIndex, let caretEnd = text[afterCaret...].firstIndex(of: "^") {
          appendNormal(text[cursor..<caretStart])
          let payload = text[afterCaret..<caretEnd]
          let attributed = AttributedString(String(payload), attributes: self.attributes)
          let segment = Text(attributed).font(.caption2).baselineOffset(6)
          self.result = self.result + segment
          cursor = text.index(after: caretEnd)
          continue
        }
      }

      // Look for _{...} subscript
      if let underStart = text[cursor...].range(of: "_{") {
        let afterBrace = underStart.upperBound
        if let braceEnd = text[afterBrace...].firstIndex(of: "}") {
          appendNormal(text[cursor..<underStart.lowerBound])
          let payload = text[afterBrace..<braceEnd]
          let attributed = AttributedString(String(payload), attributes: self.attributes)
          let segment = Text(attributed).font(.caption2).baselineOffset(-3)
          self.result = self.result + segment
          cursor = text.index(after: braceEnd)
          continue
        }
      }

      // No more patterns found, emit rest
      break
    }
    appendNormal(text[cursor...])
  }

  private mutating func renderSoftBreak() {
    switch self.softBreakMode {
    case .space where self.shouldSkipNextWhitespace:
      self.shouldSkipNextWhitespace = false
    case .space:
      self.defaultRender(.softBreak)
    case .lineBreak:
      self.shouldSkipNextWhitespace = true
      self.defaultRender(.lineBreak)
    }
  }

  private mutating func renderHTML(_ html: String) {
    let tag = HTMLTag(html)

    switch tag?.name.lowercased() {
    case "br":
      self.defaultRender(.lineBreak)
      self.shouldSkipNextWhitespace = true
    default:
      self.defaultRender(.html(html))
    }
  }

  private mutating func renderImage(_ source: String) {
    if let image = self.images[source] {
      self.result = self.result + Text(image)
    }
  }

  private mutating func defaultRender(_ inline: InlineNode) {
    self.result =
      self.result
      + Text(
        inline.renderAttributedString(
          baseURL: self.baseURL,
          textStyles: self.textStyles,
          softBreakMode: self.softBreakMode,
          attributes: self.attributes
        )
      )
  }
}
