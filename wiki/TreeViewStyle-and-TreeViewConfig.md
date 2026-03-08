# TreeViewStyle & TreeViewConfig

`SuperTreeView` accepts two configuration objects that together control how the tree looks and how users interact with it.

---

## TreeViewStyle

Controls visual appearance. Pass it via the `style` prop.

```dart
SuperTreeView<T>(
  style: const TreeViewStyle(
    indentAmount: 20,
    selectedColor: Color(0xFF0078D4),
  ),
  ...
)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `padding` | `EdgeInsetsGeometry` | `symmetric(vertical: 4, horizontal: 8)` | Padding applied to each node row |
| `indentAmount` | `double` | `24.0` | Horizontal pixels added per depth level |
| `textStyle` | `TextStyle?` | `null` | Text style for node labels |
| `labelStyle` | `TextStyle?` | `null` | Additional label-specific text style |
| `idleColor` | `Color` | `Colors.transparent` | Row background when idle |
| `hoverColor` | `Color` | `0x1A000000` (light grey) | Row background when hovered |
| `selectedColor` | `Color` | `0x33000000` (darker grey) | Row background when selected |
| `dropIndicatorColor` | `Color` | `Colors.blue` | Color of the drag-and-drop position indicator |
| `expandAnimationDuration` | `Duration` | `200 ms` | Duration for expand/collapse animations (e.g. caret rotation) |

### copyWith

```dart
final compactStyle = const TreeViewStyle().copyWith(
  indentAmount: 16,
  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
);
```

### Theme presets

If you use the prebuilt `FileSystemSuperTree`, you can apply one of the built-in theme presets via `SuperTreeThemes`:

```dart
import 'package:super_tree/super_tree.dart';

final preset = SuperTreeThemes.vscode();   // VS Code dark look
// or SuperTreeThemes.material()           // Material Design
// or SuperTreeThemes.compact()            // compact density

Theme(
  data: preset.toThemeData(),
  child: FileSystemSuperTree(...),
)
```

---

## TreeViewConfig

Controls interaction behavior. Pass it via the `logic` prop.

```dart
SuperTreeView<T>(
  logic: TreeViewConfig<T>(
    expansionTrigger: ExpansionTrigger.iconTap,
    selectionMode: SelectionMode.multiple,
    enableDragAndDrop: false,
  ),
  ...
)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `expansionTrigger` | `ExpansionTrigger` | `tap` | What action expands/collapses a node |
| `selectionMode` | `SelectionMode` | `single` | How many nodes can be selected |
| `namingStrategy` | `TreeNamingStrategy` | `none` | How in-tree renaming is triggered |
| `enableDragAndDrop` | `bool` | `true` | Allow nodes to be dragged and dropped |
| `defaultSortComparator` | `Comparator<TreeNode<T>>?` | `null` | Applied to the auto-created internal controller |
| `onNodeTap` | `void Function(String id)?` | `null` | Called on single tap |
| `onNodeDoubleTap` | `void Function(String id)?` | `null` | Called on double tap |
| `canAcceptDrop` | callback | `null` | Validates a single-node drop |
| `canAcceptDropMany` | callback | `null` | Validates a multi-node drop |
| `dropEdgeBandFraction` | `double` | `0.05` | Top/bottom edge band for above/below drop classification |
| `dropEdgeBandFractionForLeaf` | `double` | `0.2` | Stricter edge band for leaf nodes |
| `dropPositionHysteresisPx` | `double` | `8.0` | Pixel buffer to reduce drop-zone flicker |
| `enableDragAutoScroll` | `bool` | `true` | Auto-scroll when dragging near viewport edges |
| `dragAutoScrollEdgeThresholdPx` | `double` | `48.0` | Distance from edge that triggers auto-scroll |
| `dragAutoScrollMaxStepPx` | `double` | `20.0` | Maximum pixels scrolled per drag-move event |
| `debugMode` | `bool` | `false` | Print lifecycle logs to the Flutter console |

### ExpansionTrigger

| Value | Description |
|-------|-------------|
| `iconTap` | Only the caret/icon area triggers expansion |
| `tap` | Single tap anywhere on the row |
| `doubleTap` | Double tap anywhere on the row |

### SelectionMode

| Value | Description |
|-------|-------------|
| `none` | No selection |
| `single` | One node at a time |
| `multiple` | Ctrl/Cmd + click for multi-select; Shift + click for range |

### TreeNamingStrategy

| Value | Description |
|-------|-------------|
| `none` | In-tree renaming disabled |
| `doubleClick` | Start rename on double-click |
| `click` | Start rename on single click (good for todo lists) |
| `contextMenu` | Only triggered programmatically via context menu |
| `always` | Node is always in an editable state |

### copyWith

```dart
final noDropConfig = const TreeViewConfig<MyData>().copyWith(
  enableDragAndDrop: false,
  selectionMode: SelectionMode.none,
);
```

---

## Quick example: read-only compact explorer

```dart
SuperTreeView<String>(
  roots: roots,
  style: const TreeViewStyle(
    indentAmount: 16,
    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    selectedColor: Color(0x220078D4),
    hoverColor: Color(0x110078D4),
  ),
  logic: const TreeViewConfig(
    expansionTrigger: ExpansionTrigger.iconTap,
    selectionMode: SelectionMode.single,
    enableDragAndDrop: false,
  ),
  prefixBuilder: (context, node) =>
      Icon(node.hasChildren ? Icons.folder : Icons.description, size: 16),
  contentBuilder: (context, node, _) => Text(node.data),
)
```

---

## See also

- [SuperTreeView](SuperTreeView) — widget API overview
- [Drag and Drop](Drag-and-Drop) — `canAcceptDrop` and drop position details
- [Keyboard Navigation](Keyboard-Navigation) — keyboard interaction reference
- [Prebuilt Widgets](Prebuilt-Widgets) — `SuperTreeThemes` presets
