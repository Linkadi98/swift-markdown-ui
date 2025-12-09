import SwiftUI

@available(iOS 15.0, *)
struct ListItemView: View {
  @Environment(\.theme.listItem) private var listItem
  @Environment(\.listLevel) private var listLevel
  @Environment(\.markdownRemainingLines) private var remainingLines
  @Environment(\.markdownAggregateIndex) private var aggregateIndex

  private let item: RawListItem
  private let number: Int
  private let markerStyle: BlockStyle<ListMarkerConfiguration>
  private let markerWidth: CGFloat?

  init(
    item: RawListItem,
    number: Int,
    markerStyle: BlockStyle<ListMarkerConfiguration>,
    markerWidth: CGFloat?
  ) {
    self.item = item
    self.number = number
    self.markerStyle = markerStyle
    self.markerWidth = markerWidth
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
      self.markerStyle
        .makeBody(configuration: .init(listLevel: self.listLevel, itemNumber: self.number))
        .textStyleFont()
        .readWidth(column: 0)
        .frame(width: self.markerWidth, alignment: .trailing)
    }
    #if os(visionOS)
      .labelStyle(BulletItemStyle())
    #endif
  }
}

@available(iOS 15.0, *)
extension VerticalAlignment {
  private enum CenterOfFirstLine: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
      let heightAfterFirstLine = context[.lastTextBaseline] - context[.firstTextBaseline]
      let heightOfFirstLine = context.height - heightAfterFirstLine
      return heightOfFirstLine / 2
    }
  }
  static let centerOfFirstLine = Self(CenterOfFirstLine.self)
}

@available(iOS 15.0, *)
struct BulletItemStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(alignment: .centerOfFirstLine, spacing: 4) {
      configuration.icon
      configuration.title
    }
  }
}
