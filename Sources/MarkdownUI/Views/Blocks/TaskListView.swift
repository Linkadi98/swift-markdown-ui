import SwiftUI

@available(iOS 15.0, *)
struct TaskListView: View {
  @Environment(\.theme.list) private var list
  @Environment(\.listLevel) private var listLevel

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
    } else {
      blockSeq
        .environment(\.listLevel, self.listLevel + 1)
        .environment(\.tightSpacingEnabled, self.isTight)
    }
  }
}
