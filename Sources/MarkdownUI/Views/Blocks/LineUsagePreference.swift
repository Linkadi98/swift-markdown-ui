import SwiftUI

@available(iOS 15.0, *)
struct LineUsagePreferenceKey: PreferenceKey {
  static var defaultValue: Int = 0
  static func reduce(value: inout Int, nextValue: () -> Int) {
    value += nextValue()
  }
}
