/// Optional shared contract for tree node payload models.
///
/// Use this interface when your app wants a consistent shape for common
/// tree concepts (for example, icon metadata and child/container capability)
/// without forcing a specific concrete data type.
abstract interface class SuperTreeNodeContract {
  /// Whether this node is conceptually allowed to contain children.
  bool get canHaveChildren;

  /// Optional app-defined icon metadata token for this node.
  ///
  /// The package does not interpret this value. UI layers can map it to
  /// `IconData`, image assets, emoji, or custom widget factories.
  Object? get iconToken;
}
