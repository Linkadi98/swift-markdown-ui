import SwiftUI

@available(iOS 15.0, *)
struct BulletedListView: View {
  @Environment(\.theme.list) private var list
  @Environment(\.theme.bulletedListMarker) private var bulletedListMarker
  @Environment(\.listLevel) private var listLevel
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownAggregateIndex) private var aggregateIndex
  @Environment(\.markdownBlockIndex) private var blockIndex

  private let isTight: Bool
  private let items: [RawListItem]

  init(isTight: Bool, items: [RawListItem]) {
    self.isTight = isTight
    self.items = items
  }

  var body: some View {
    self.list.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: .bulletedList(isTight: self.isTight, items: self.items))
      )
    )
    .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
      // Aggregate all line counts from nested items and report as this block's total
      let total = values.values.reduce(0, +)
      if total > 0 {
        mdDbg("📋 BulletedListView aggregated \(total) lines from \(values.count) items")
      }
    }
    .background(
      GeometryReader { _ in
        Color.clear.preference(
          key: BlockLinesPreferenceKey.self,
          value: self.shouldPublish ? [self.publishIndex(): 0] : [:]
        )
      }
    )
    .transformPreference(BlockLinesPreferenceKey.self) { pref in
      // Replace nested reports with our own aggregated report
      if self.shouldPublish {
        let total = pref.values.reduce(0, +)
        pref = [self.publishIndex(): total]
      }
    }
  }

  private var shouldPublish: Bool {
    remainingLines >= 1000
  }

  private func publishIndex() -> Int {
    aggregateIndex ?? blockIndex ?? 0
  }

  private var label: some View {
    ListItemSequence(items: self.items, markerStyle: self.bulletedListMarker)
      .environment(\.listLevel, self.listLevel + 1)
      .environment(\.tightSpacingEnabled, self.isTight)
      .environment(\.markdownRemainingLines, self.remainingLines)
      .environment(\.markdownAggregateIndex, self.aggregateIndex)
  }
}
