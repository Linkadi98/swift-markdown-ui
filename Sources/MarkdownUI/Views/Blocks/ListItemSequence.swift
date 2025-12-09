import SwiftUI

@available(iOS 15.0, *)
final class ListItemSequenceViewModel: ObservableObject {
  @Published var itemLines: [Int: Int] = [:]

  let totalItems: Int

  init(totalItems: Int) {
    self.totalItems = totalItems
  }

  func applyMeasuredLines(_ values: [Int: Int]) {
    guard !values.isEmpty else { return }
    if values == itemLines { return }
    itemLines = values
    mdDbg("📋 ListItemSequence measured \(values.count) items: \(values)")
  }

  // Compute which items to show and what limit to apply to last item
  func visibleItems(remainingLines: Int) -> [(index: Int, limit: Int?)] {
    if remainingLines >= 1000 {
      // Measurement pass - show all items
      return (0..<totalItems).map { (index: $0, limit: nil) }
    }

    var budget = remainingLines
    var result: [(index: Int, limit: Int?)] = []

    for idx in 0..<totalItems {
      let measured = itemLines[idx]
      let contribution = measured ?? 1  // fallback to 1 line if not measured yet

      if contribution <= budget {
        result.append((idx, nil))
        budget -= contribution
      } else {
        // Last item - show partially if budget > 0
        if budget > 0 {
          result.append((idx, budget))
        }
        break
      }

      if budget <= 0 { break }
    }

    mdDbg(
      "📋 ListItemSequence visibleItems - budget=\(remainingLines), showing \(result.count) items")
    return result
  }
}

@available(iOS 15.0, *)
struct ListItemSequence: View {
  @Environment(\.markdownRemainingLines) private var remainingLines
  @StateObject private var viewModel: ListItemSequenceViewModel

  private let items: [RawListItem]
  private let start: Int
  private let markerStyle: BlockStyle<ListMarkerConfiguration>
  private let markerWidth: CGFloat?

  init(
    items: [RawListItem],
    start: Int = 1,
    markerStyle: BlockStyle<ListMarkerConfiguration>,
    markerWidth: CGFloat? = nil
  ) {
    self.items = items
    self.start = start
    self.markerStyle = markerStyle
    self.markerWidth = markerWidth
    _viewModel = StateObject(wrappedValue: ListItemSequenceViewModel(totalItems: items.count))
  }

  var body: some View {
    let visible = viewModel.visibleItems(remainingLines: remainingLines)

    let content = VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(visible.enumerated()), id: \.offset) { _, itemInfo in
        ListItemView(
          item: items[itemInfo.index],
          number: start + itemInfo.index,
          markerStyle: markerStyle,
          markerWidth: markerWidth
        )
        .environment(\.markdownRemainingLines, itemInfo.limit ?? 1000)
        .environment(\.markdownAggregateIndex, itemInfo.index)
      }
    }
    .onPreferenceChange(BlockLinesPreferenceKey.self) { values in
      viewModel.applyMeasuredLines(values)
    }

    if #available(iOS 14.5, macOS 11.3, tvOS 14.5, watchOS 7.4, *) {
      content.labelStyle(.titleAndIcon)
    } else {
      content
    }
  }
}
