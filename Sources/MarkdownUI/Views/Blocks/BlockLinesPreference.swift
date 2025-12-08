import SwiftUI

@available(iOS 15.0, *)
struct BlockLinesPreferenceKey: PreferenceKey {
  static var defaultValue: [Int: Int] = [:]
  static func reduce(value: inout [Int: Int], nextValue: () -> [Int: Int]) {
    // Sum line counts per block index so composite blocks aggregate children
    value.merge(nextValue(), uniquingKeysWith: { old, new in old + new })
  }
}
