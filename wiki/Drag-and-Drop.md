# Drag and Drop

`super_tree` includes built-in drag-and-drop support for both single and multi-node moves. Everything is wired up automatically — you only need to configure the behavior you want.

---

## Enabling drag-and-drop

Drag-and-drop is **enabled by default**. Disable it globally via `TreeViewConfig`:

```dart
SuperTreeView<T>(
  logic: const TreeViewConfig(
    enableDragAndDrop: false,
  ),
  ...
)
```

---

## Drop positions

When a node is dragged over a target node, the drop position is classified as one of three values:

| `NodeDropPosition` | Meaning |
|--------------------|---------|
| `above` | Insert the dragged node as a sibling above the target |
| `inside` | Nest the dragged node as a child of the target |
| `below` | Insert the dragged node as a sibling below the target |

The top and bottom edges of the target row are treated as above/below zones; the middle is the "inside" zone. Zone sizes are controlled by `dropEdgeBandFraction` (default `0.05` — top/bottom 5% of the row) and `dropEdgeBandFractionForLeaf` (default `0.2` for leaf nodes).

---

## Validating drops

### Single-node validation

Return `false` from `canAcceptDrop` to reject a drop:

```dart
TreeViewConfig<FileSystemItem>(
  canAcceptDrop: (dragged, target, position) {
    // Files cannot receive items dropped inside them
    if (target.data is FileItem && position == NodeDropPosition.inside) {
      return false;
    }
    return true;
  },
)
```

### Multi-node validation

When multiple nodes are selected and dragged as a batch, `canAcceptDropMany` is called:

```dart
TreeViewConfig<FileSystemItem>(
  canAcceptDropMany: (draggedNodes, target, position) {
    // Only allow dropping into folders
    return target.data is FolderItem || position != NodeDropPosition.inside;
  },
  // canAcceptDrop is used as a per-node fallback when canAcceptDropMany is null
)
```

When `canAcceptDropMany` is `null`, `canAcceptDrop` is called once per dragged node and the drop is accepted only if all calls return `true`.

> **Cycle protection:** The controller always rejects drops that would create circular references, regardless of your validation callback.

---

## Responding to a drop

When a drop is accepted, `TreeController.moveNode` or `TreeController.moveNodes` is called automatically. You do not need to wire this yourself.

If you need to react to a move (e.g. to persist the new order), listen to the controller:

```dart
controller.addListener(() {
  // roots and flatVisibleNodes now reflect the new order
  saveToDisk(controller.roots);
});
```

---

## Multi-node drag

When `selectionMode` is `SelectionMode.multiple`, dragging a selected node automatically drags all selected nodes as a batch. The payload contains both the primary node and the full list:

```dart
// Internally, the drag payload is:
class TreeDragPayload<T> {
  final TreeNode<T> primaryNode;  // where the drag started
  final List<TreeNode<T>> nodes;  // all dragged nodes
  bool get isBatch => nodes.length > 1;
}
```

Batch moves are applied atomically — either all nodes move or none do.

---

## Auto-scroll

When dragging near the top or bottom of the visible viewport, the list auto-scrolls. Tune the behavior with:

```dart
TreeViewConfig(
  enableDragAutoScroll: true,           // on by default
  dragAutoScrollEdgeThresholdPx: 48.0,  // pixels from edge that triggers scroll
  dragAutoScrollMaxStepPx: 20.0,        // max pixels scrolled per drag move
)
```

---

## Drop indicator styling

Customize the color of the drop indicator line/highlight via `TreeViewStyle`:

```dart
TreeViewStyle(
  dropIndicatorColor: Colors.blue,
)
```

---

## Drop zone tuning

Fine-tune how much of the node row is treated as the edge zones (above/below) vs. the centre zone (inside):

```dart
TreeViewConfig(
  dropEdgeBandFraction: 0.1,         // top/bottom 10% = above/below zone
  dropEdgeBandFractionForLeaf: 0.3,  // wider edge band for leaf nodes
  dropPositionHysteresisPx: 8.0,     // pixel buffer to reduce zone flicker
)
```

---

## Complete example

```dart
SuperTreeView<FileSystemItem>(
  controller: _controller,
  style: const TreeViewStyle(
    dropIndicatorColor: Colors.deepPurple,
  ),
  logic: TreeViewConfig<FileSystemItem>(
    enableDragAndDrop: true,
    selectionMode: SelectionMode.multiple,
    canAcceptDrop: (dragged, target, position) {
      if (position == NodeDropPosition.inside && target.data is FileItem) {
        return false; // cannot drop inside a file
      }
      return true;
    },
    canAcceptDropMany: (draggedNodes, target, position) {
      return target.data is FolderItem || position != NodeDropPosition.inside;
    },
  ),
  prefixBuilder: (context, node) => Icon(
    node.data.isFolder ? Icons.folder : Icons.insert_drive_file,
  ),
  contentBuilder: (context, node, _) => Text(node.data.name),
)
```

---

## See also

- [TreeController](TreeController) — `moveNode`, `moveNodes`, cycle protection
- [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) — full config reference
- [Keyboard Navigation](Keyboard-Navigation) — keyboard-driven tree interaction
