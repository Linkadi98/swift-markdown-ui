import Foundation

// Toggleable, lightweight logging for MarkdownUI internals.
// Disabled by default; enable from your app if needed:
// MarkdownDebug.enabled = true
enum MarkdownDebug {
  static var enabled: Bool = false
}

@inline(__always)
func mdDbg(_ message: @autoclosure () -> String) {
  guard MarkdownDebug.enabled else { return }
  print(message())
}
