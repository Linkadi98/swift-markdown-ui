import SwiftUI

@available(iOS 15.0, *)
struct NumberedListView: View {
  @Environment(\.theme.list) private var list
  @Environment(\.theme.numberedListMarker) private var numberedListMarker
  @Environment(\.listLevel) private var listLevel
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownAggregateIndex) private var aggregateIndex
  @Environment(\.markdownBlockIndex) private var blockIndex

  @State private var markerWidth: CGFloat?

  private let isTight: Bool
  private let start: Int
  private let items: [RawListItem]

  init(isTight: Bool, start: Int, items: [RawListItem]) {
    self.isTight = isTight
    self.start = start
    self.items = items
  }

  var body: some View {
    self.list.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(
          block: .numberedList(
            isTight: self.isTight,
            start: self.start,
            items: self.items
          )
        )
      )
    )
    .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
      let total = values.values.reduce(0, +)
      if total > 0 {
        mdDbg("📋 NumberedListView aggregated \(total) lines from \(values.count) items")
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
    aggregateIndex ?? blockIndex
  }

  private var label: some View {
    ListItemSequence(
      items: self.items,
      start: self.start,
      markerStyle: self.numberedListMarker,
      markerWidth: self.markerWidth
    )
    .environment(\.listLevel, self.listLevel + 1)
    .environment(\.tightSpacingEnabled, self.isTight)
    .environment(\.markdownRemainingLines, self.remainingLines)
    .environment(\.markdownAggregateIndex, self.aggregateIndex)
    .onColumnWidthChange { columnWidths in
      self.markerWidth = columnWidths[0]
    }
  }
}
