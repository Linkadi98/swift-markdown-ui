import SwiftUI

@available(iOS 15.0, *)
extension EnvironmentValues {
  var markdownMaxLines: Int? {
    get { self[MarkdownMaxLinesKey.self] }
    set { self[MarkdownMaxLinesKey.self] = newValue }
  }

  var markdownRemainingLines: Int {
    get { self[MarkdownRemainingLinesKey.self] }
    set { self[MarkdownRemainingLinesKey.self] = newValue }
  }

  // The index of the current block being rendered; used for per-block measurements
  var markdownBlockIndex: Int {
    get { self[MarkdownBlockIndexKey.self] }
    set { self[MarkdownBlockIndexKey.self] = newValue }
  }
}

@available(iOS 15.0, *)
private struct MarkdownMaxLinesKey: EnvironmentKey {
  static let defaultValue: Int? = nil
}

@available(iOS 15.0, *)
private struct MarkdownRemainingLinesKey: EnvironmentKey {
  static let defaultValue: Int = 1000  // Use large but safe value instead of .max
}

@available(iOS 15.0, *)
private struct MarkdownBlockIndexKey: EnvironmentKey {
  static let defaultValue: Int = -1
}
