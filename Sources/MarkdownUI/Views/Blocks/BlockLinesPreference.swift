import SwiftUI

@available(iOS 15.0, *)
struct BlockLinesPreferenceKey: PreferenceKey {
  static var defaultValue: [Int: Int] = [:]
  static func reduce(value: inout [Int: Int], nextValue: () -> [Int: Int]) {
    value.merge(nextValue(), uniquingKeysWith: { old, new in old + new })
  }
}
// Deprecated: BlockLinesPreferenceKey removed. Line counting now uses
// LineCountUpdateModifier in Utility/LineCount.swift.
