import Foundation

@inline(__always)
func mdDbg(_ message: @autoclosure () -> String) {
  debugPrint(message())
}
