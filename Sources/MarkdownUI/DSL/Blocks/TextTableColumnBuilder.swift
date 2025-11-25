import Foundation

/// A result builder that creates table columns from closures.
///
/// You don't call the methods of the result builder directly. Instead, MarkdownUI annotates the `columns`
/// parameter of the various ``TextTable`` initializers with the `@TextTableColumnBuilder` attribute,
/// implicitly calling this builder for you.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@resultBuilder public enum TextTableColumnBuilder<RowValue> {
  public static func buildBlock(
    _ components: [TextTableColumn<RowValue>]...
  ) -> [TextTableColumn<RowValue>] {
    components.flatMap { $0 }
  }

  public static func buildExpression(
    _ expression: TextTableColumn<RowValue>
  ) -> [TextTableColumn<RowValue>] {
    [expression]
  }

  public static func buildArray(
    _ components: [[TextTableColumn<RowValue>]]
  ) -> [TextTableColumn<RowValue>] {
    components.flatMap { $0 }
  }

  public static func buildOptional(
    _ component: [TextTableColumn<RowValue>]?
  ) -> [TextTableColumn<RowValue>] {
    component ?? []
  }

  public static func buildEither(
    first component: [TextTableColumn<RowValue>]
  ) -> [TextTableColumn<RowValue>] {
    component
  }

  public static func buildEither(
    second component: [TextTableColumn<RowValue>]
  ) -> [TextTableColumn<RowValue>] {
    component
  }
}
