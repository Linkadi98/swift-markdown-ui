import SwiftUI

@available(iOS 15.0, *)
struct BlockLinesPreferenceKey: PreferenceKey {
  static var defaultValue: [Int: Int] = [:]
  static func reduce(value: inout [Int: Int], nextValue: () -> [Int: Int]) {
    // Merge, preferring latest measurements for an index
    value.merge(nextValue(), uniquingKeysWith: { _, new in new })
  }
}
