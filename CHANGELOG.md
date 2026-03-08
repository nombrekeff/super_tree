## 0.2.0

**Breaking changes**

- Grouped all drag-and-drop settings into two dedicated sub-objects to keep the top-level classes lean:
  - `TreeDragAndDropConfig<T>` – holds `enabled`, `canAcceptDrop`, `canAcceptDropMany`, `dropEdgeBandFraction`, `dropEdgeBandFractionForLeaf`, `dropPositionHysteresisPx`, `enableAutoScroll`, `autoScrollEdgeThresholdPx`, `autoScrollMaxStepPx`.
  - `TreeDragAndDropStyle` – holds `indicatorColor`.
- `TreeViewConfig` now exposes a single `dragAndDrop` field of type `TreeDragAndDropConfig<T>`.  The previously flat DnD fields (`enableDragAndDrop`, `canAcceptDrop`, `canAcceptDropMany`, `dropEdgeBandFraction`, `dropEdgeBandFractionForLeaf`, `dropPositionHysteresisPx`, `enableDragAutoScroll`, `dragAutoScrollEdgeThresholdPx`, `dragAutoScrollMaxStepPx`) have been removed.
- `TreeViewStyle` now exposes a single `dragAndDrop` field of type `TreeDragAndDropStyle`.  The previously flat `dropIndicatorColor` field has been removed.
- `NodeDropPosition` has moved from `tree_drag_and_drop_wrapper.dart` to the new `tree_drag_and_drop_config.dart` and is still exported from the top-level barrel (`super_tree.dart`).

**Migration**

Before:
```dart
TreeViewConfig(
  enableDragAndDrop: true,
  canAcceptDrop: (dragged, target, pos) => true,
  dropEdgeBandFraction: 0.1,
  enableDragAutoScroll: true,
  dragAutoScrollEdgeThresholdPx: 48,
  dragAutoScrollMaxStepPx: 20,
)

TreeViewStyle(
  dropIndicatorColor: Colors.blue,
)
```

After:
```dart
TreeViewConfig(
  dragAndDrop: TreeDragAndDropConfig(
    enabled: true,
    canAcceptDrop: (dragged, target, pos) => true,
    dropEdgeBandFraction: 0.1,
    enableAutoScroll: true,
    autoScrollEdgeThresholdPx: 48,
    autoScrollMaxStepPx: 20,
  ),
)

TreeViewStyle(
  dragAndDrop: TreeDragAndDropStyle(
    indicatorColor: Colors.blue,
  ),
)
```

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
