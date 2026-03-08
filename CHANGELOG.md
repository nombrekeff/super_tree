## 0.3.0

- Removed obsolete `test/public_api_aliases_test.dart`, which no longer reflected
  the maintained public API surface.
- Updated installation guidance in package docs and wiki to the current release
  line.
- Updated README controller usage example to use `TreeController<T>`.

## 0.2.0

- Added `SuperTree*` public API aliases for user-facing naming consistency, including:
  `SuperTreeController`, `SuperTreeSearchController`, `SuperTreeNode`,
  `SuperTreeViewConfig`, `SuperTreeViewStyle`, and `SuperTreeEvent` variants.
- Added dedicated per-event streams on `TreeController`:
  `nodeAddedEvents`, `nodeRemovedEvents`, `nodeMovedEvents`, and
  `nodeRenamedEvents`.
- Added convenience listener helpers on `TreeController`:
  `addNodeAddedListener`, `addNodeRemovedListener`, `addNodeMovedListener`,
  and `addNodeRenamedListener`.
- Added an optional shared payload contract, `SuperTreeNodeContract`, with
  default integration in `SuperTreeData` (`canHaveChildren` + `iconToken`).

## 0.1.1

- Added `TreeController.events`, a typed broadcast `Stream<TreeEvent<T>>` that lets consumers listen
  to specific structural mutations instead of the generic `ChangeNotifier` notification.
  Supported events: `TreeNodeAddedEvent`, `TreeNodeRemovedEvent`, `TreeNodeMovedEvent`,
  `TreeNodeRenamedEvent`.

## 0.1.0

- First public release of `super_tree`.
- Added `SuperTreeView` with optional internal/external `TreeController` support.
- Added desktop and mobile interactions: keyboard navigation, right-click/long-press context menus, and drag-and-drop support.
- Added prebuilt widgets: `FileSystemSuperTree` and `TodoListSuperTree`.
- Added search/filter architecture with fuzzy matching and highlighted labels.
- Added lazy-loading support with per-node loading/error state tracking.
- Added controller state persistence for expanded and selected node IDs.
- Added theme presets and icon-provider customization for file system scenarios.
- Added extensive examples and test coverage for controller and widget behavior.
