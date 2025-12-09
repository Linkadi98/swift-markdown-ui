import SwiftUI

@available(iOS 15.0, *)
struct TaskListItemView: View {
  @Environment(\.theme.listItem) private var listItem
  @Environment(\.theme.taskListMarker) private var taskListMarker
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownAggregateIndex) private var aggregateIndex

  private let item: RawTaskListItem

  init(item: RawTaskListItem) {
    self.item = item
  }

  var body: some View {
    self.listItem.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(blocks: item.children)
      )
    )
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
    aggregateIndex ?? 0
  }

  private var label: some View {
    Label {
      ExpandableBlockSequence(self.item.children)
    } icon: {
      self.taskListMarker.makeBody(configuration: .init(isCompleted: self.item.isCompleted))
        .textStyleFont()
    }
  }
}
