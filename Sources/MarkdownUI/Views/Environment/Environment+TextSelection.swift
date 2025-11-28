import SwiftUI

@available(iOS 15.0, *)
extension EnvironmentValues {
  var markdownTextSelectionEnabled: Bool {
    get { self[MarkdownTextSelectionKey.self] }
    set { self[MarkdownTextSelectionKey.self] = newValue }
  }
}

@available(iOS 15.0, *)
private struct MarkdownTextSelectionKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

@available(iOS 15.0, *)
extension View {
  /// Enables text selection for markdown content.
  /// When enabled, users can select text character by character like in UITextView.
  /// When disabled (default), markdown renders with proper styling and formatting.
  public func markdownTextSelection(_ enabled: Bool) -> some View {
    environment(\.markdownTextSelectionEnabled, enabled)
  }
}
