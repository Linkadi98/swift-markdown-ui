import Foundation

@available(iOS 15.0, *)
extension InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) -> AttributedString {
    var renderer = AttributedStringInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      softBreakMode: softBreakMode,
      attributes: attributes
    )
    renderer.render(self)
    return renderer.result.resolvingFonts()
  }
}

@available(iOS 15.0, *)
extension Sequence where Element == InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) -> AttributedString {
    var renderer = AttributedStringInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      softBreakMode: softBreakMode,
      attributes: attributes
    )
    renderer.render(self)
    return renderer.result.resolvingFonts()
  }
}

@available(iOS 15.0, *)
private struct AttributedStringInlineRenderer {
  var result = AttributedString()

  private let baseURL: URL?
  private let textStyles: InlineTextStyles
  private let softBreakMode: SoftBreak.Mode
  private var attributes: AttributeContainer
  private var shouldSkipNextWhitespace = false

  init(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) {
    self.baseURL = baseURL
    self.textStyles = textStyles
    self.softBreakMode = softBreakMode
    self.attributes = attributes
  }

  mutating func render<S: Sequence>(_ inlines: S) where S.Element == InlineNode {
    for inline in inlines {
      self.render(inline)
    }
  }

  mutating func render(_ inline: InlineNode) {
    switch inline {
    case .text(let content):
      self.renderText(content)
    case .softBreak:
      self.renderSoftBreak()
    case .lineBreak:
      self.renderLineBreak()
    case .code(let content):
      self.renderCode(content)
    case .html(let content):
      self.renderHTML(content)
    case .emphasis(let children):
      self.renderEmphasis(children: children)
    case .strong(let children):
      self.renderStrong(children: children)
    case .strikethrough(let children):
      self.renderStrikethrough(children: children)
    case .link(let destination, let children):
      self.renderLink(destination: destination, children: children)
    case .image(let source, let children):
      self.renderImage(source: source, children: children)
    }
  }

  private mutating func renderText(_ text: String) {
    var text = text

    if self.shouldSkipNextWhitespace {
      self.shouldSkipNextWhitespace = false
      text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }

    // Simple check to avoid conflicts with strikethrough - just do basic parsing

    // Custom: lightweight parse for ^superscript^ and _{subscript}
    // Use different delimiters to avoid conflict: ^...^ for superscript, _{...} for subscript
    var cursor = text.startIndex
    func appendNormal(_ s: Substring) {
      guard !s.isEmpty else { return }
      self.result += .init(String(s), attributes: self.attributes)
    }

    while cursor < text.endIndex {
      // Look for ^...^ superscript
      if let caretStart = text[cursor...].firstIndex(of: "^") {
        let afterCaret = text.index(after: caretStart)
        if afterCaret < text.endIndex, let caretEnd = text[afterCaret...].firstIndex(of: "^") {
          appendNormal(text[cursor..<caretStart])
          let payload = text[afterCaret..<caretEnd]
          var attrs = self.attributes
          attrs.font = .caption2
          if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            attrs[AttributeScopes.SwiftUIAttributes.BaselineOffsetAttribute.self] = 6
          }
          self.result += .init(String(payload), attributes: attrs)
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
          var attrs = self.attributes
          attrs.font = .caption2
          if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            attrs[AttributeScopes.SwiftUIAttributes.BaselineOffsetAttribute.self] = -3
          }
          self.result += .init(String(payload), attributes: attrs)
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
    switch softBreakMode {
    case .space where self.shouldSkipNextWhitespace:
      self.shouldSkipNextWhitespace = false
    case .space:
      self.result += .init(" ", attributes: self.attributes)
    case .lineBreak:
      self.renderLineBreak()
    }
  }

  private mutating func renderLineBreak() {
    self.result += .init("\n", attributes: self.attributes)
  }

  private mutating func renderCode(_ code: String) {
    self.result += .init(code, attributes: self.textStyles.code.mergingAttributes(self.attributes))
  }

  private mutating func renderHTML(_ html: String) {
    let tag = HTMLTag(html)

    switch tag?.name.lowercased() {
    case "br":
      self.renderLineBreak()
      self.shouldSkipNextWhitespace = true
    default:
      self.renderText(html)
    }
  }

  private mutating func renderEmphasis(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.emphasis.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrong(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strong.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrikethrough(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strikethrough.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderLink(destination: String, children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.link.mergingAttributes(self.attributes)
    self.attributes.link = URL(string: destination, relativeTo: self.baseURL)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderImage(source: String, children: [InlineNode]) {
    // AttributedString does not support images
  }
}

@available(iOS 15.0, *)
extension TextStyle {
  fileprivate func mergingAttributes(_ attributes: AttributeContainer) -> AttributeContainer {
    var newAttributes = attributes
    self._collectAttributes(in: &newAttributes)
    return newAttributes
  }
}
