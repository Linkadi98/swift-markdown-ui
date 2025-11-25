import SwiftUI

@available(iOS 15.0, *)
struct ListItemSequence: View {
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
  }

  @ViewBuilder
  var body: some View {
    let blockSeq = BlockSequence(self.items) { index, item in
      ListItemView(
        item: item,
        number: self.start + index,
        markerStyle: self.markerStyle,
        markerWidth: self.markerWidth
      )
    }
    if #available(iOS 14.5, macOS 11.3, tvOS 14.5, watchOS 7.4, *) {
      blockSeq.labelStyle(.titleAndIcon)
    } else {
      blockSeq
    }
  }
}
