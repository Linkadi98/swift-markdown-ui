import SwiftUI

@available(iOS 15.0, *)
struct TaskListView: View {
  @Environment(\.theme.list) private var list
  @Environment(\.theme.taskListMarker) private var taskListMarker
  @Environment(\.listLevel) private var listLevel
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownAggregateIndex) private var aggregateIndex
  @Environment(\.markdownBlockIndex) private var blockIndex

  private let isTight: Bool
  private let items: [RawTaskListItem]

  init(isTight: Bool, items: [RawTaskListItem]) {
    self.isTight = isTight
    self.items = items
  }

  var body: some View {
    self.list.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: .taskList(isTight: self.isTight, items: self.items))
      )
    )
    .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
      let total = values.values.reduce(0, +)
      if total > 0 {
        mdDbg("📋 TaskListView aggregated \(total) lines from \(values.count) items")
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
    aggregateIndex ?? blockIndex ?? 0
  }

  @ViewBuilder
  private var label: some View {
    let blockSeq = BlockSequence(self.items) { _, item in
      TaskListItemView(item: item)
    }
    if #available(iOS 14.5, macOS 11.3, tvOS 14.5, watchOS 7.4, *) {
      blockSeq
        .labelStyle(.titleAndIcon)
        .environment(\.listLevel, self.listLevel + 1)
        .environment(\.tightSpacingEnabled, self.isTight)
        .environment(\.markdownRemainingLines, self.remainingLines)
        .environment(\.markdownAggregateIndex, self.aggregateIndex)
    } else {
      blockSeq
        .environment(\.listLevel, self.listLevel + 1)
        .environment(\.tightSpacingEnabled, self.isTight)
        .environment(\.markdownRemainingLines, self.remainingLines)
        .environment(\.markdownAggregateIndex, self.aggregateIndex)
    }
  }
}
