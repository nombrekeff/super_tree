## Unreleased

- Added customizable node cursor support through `TreeViewConfig.nodeCursorResolver`, including default per-state cursors for row, expansion toggle, rename mode, and non-interactive rows.

## 0.2.1

- Fixed README preview image references and aligned the wiki documentation image references.

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
