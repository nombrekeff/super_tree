# TreeController

`TreeController<T>` manages all tree state independently of the UI. It extends `ChangeNotifier` so `SuperTreeView` automatically rebuilds when anything changes.

You can let `SuperTreeView` create its own internal controller (using the `roots` prop), or create one yourself for full programmatic control.

## Creating a controller

```dart
final controller = TreeController<MyData>(
  roots: myRootNodes,             // initial tree structure
  sortComparator: (a, b) =>       // optional: keep tree sorted
      a.data.name.compareTo(b.data.name),
  loadChildren: (node) async {    // optional: lazy child loading
    return await fetchChildren(node.data.id);
  },
  onNodeRenamed: (node, newName) {
    node.data.name = newName;     // update your data layer
  },
  onNodeDeleted: (node) {
    myDatabase.delete(node.data.id);
  },
);
```

> Always call `controller.dispose()` when the widget owning it is disposed.

## Constructor parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `roots` | `List<TreeNode<T>>?` | Initial root nodes |
| `sortComparator` | `Comparator<TreeNode<T>>?` | Keeps tree sorted after every mutation |
| `loadChildren` | `Future<List<TreeNode<T>>> Function(TreeNode<T>)?` | Lazy-loading callback |
| `onNodeRenamed` | `void Function(TreeNode<T>, String)?` | Called after a rename completes |
| `onNodeDeleted` | `void Function(TreeNode<T>)?` | Called after `removeNode` |

---

## Expansion

### `expandNode(node)` / `collapseNode(node)`

Directly expand or collapse a node. Uses a delta update (no full tree rebuild) for performance.

```dart
controller.expandNode(myNode);
controller.collapseNode(myNode);
```

### `toggleNodeExpansion(node)`

Async toggle — expands by calling `ensureNodeChildrenLoaded` first if necessary.

```dart
await controller.toggleNodeExpansion(myNode);
```

### `expandAll()` / `collapseAll()`

Recursively expand or collapse every node.

```dart
controller.expandAll();
controller.collapseAll();
```

---

## Selection

### Selection modes

Configure `SelectionMode` in `TreeViewConfig`:

| Mode | Behaviour |
|------|-----------|
| `SelectionMode.none` | Selection disabled |
| `SelectionMode.single` | One node selected at a time |
| `SelectionMode.multiple` | Ctrl/Cmd or Shift multi-select |

### Key properties

```dart
controller.selectedNodeId         // first (anchor) selected ID or null
controller.selectedNodeIds        // all selected IDs (unmodifiable Set)
```

### Methods

```dart
controller.setSelectedNodeId('node-42');   // single selection
controller.toggleSelection('node-42');     // add/remove from selection
controller.selectRange('node-99');         // extend selection to node
controller.deselectAll();

controller.selectNext();     // move selection down
controller.selectPrevious(); // move selection up
controller.selectFirst();
controller.selectLast();
```

### `getSelectedNodesInVisibleOrder({bool topLevelOnly})`

Returns selected nodes in the order they appear in the flattened visible list. When `topLevelOnly: true`, descendants of already-selected parents are omitted (useful for drag-and-drop).

```dart
final nodes = controller.getSelectedNodesInVisibleOrder(topLevelOnly: true);
```

---

## CRUD operations

### Add nodes

```dart
controller.addRoot(newRootNode);
controller.addChild(parentNode, childNode);
```

### Remove a node

```dart
controller.removeNode(node); // also triggers onNodeDeleted
```

### Move a node (drag-and-drop result)

```dart
controller.moveNode(
  dragged: draggedNode,
  target: targetNode,
  insertBefore: true,   // false = insert after
  nestInside: false,    // true = make target the new parent
);

// Move multiple nodes atomically
controller.moveNodes(
  draggedNodes: selectedNodes,
  target: targetNode,
  insertBefore: false,
  nestInside: true,
);
```

`moveNodes` validates all nodes before applying any mutation. If any node would create a cycle, the whole operation is rejected.

---

## Renaming

```dart
controller.setRenamingNodeId('node-42'); // enter rename mode
controller.renameNode('node-42', 'New Name'); // commit rename
controller.setRenamingNodeId(null); // cancel rename
```

To create a brand-new child in rename mode immediately:

```dart
controller.createNewChild(parentNode, MyData(name: ''));
controller.createNewRoot(MyData(name: ''));
```

---

## Filtering

Apply an arbitrary predicate to make only matching nodes (and their ancestors) visible:

```dart
controller.applyFilter(
  predicate: (node) => node.data.isImportant,
);

controller.clearFilter(); // restore full visibility
```

You can also supply `matchedIndicesByNodeId` to drive character-level highlighting in the UI:

```dart
controller.applyFilter(
  predicate: (node) => matchedIds.contains(node.id),
  matchedIndicesByNodeId: {'node-42': [0, 1, 3]},
);
```

---

## Finding nodes

```dart
final node = controller.findNodeById('node-42');
```

Returns `null` when no node with that ID exists. The lookup is O(1) thanks to an internal index.

```dart
// Check ancestry
final isDescendant = controller.isDescendantOf('child-id', 'ancestor-id');
```

---

## Flat visible list

The controller pre-computes a flat, ordered list of all currently visible nodes. This is what `SuperTreeView` feeds to `ListView.builder`.

```dart
final List<TreeNode<T>> visible = controller.flatVisibleNodes;
```

Call `controller.refresh()` when you mutate node data in-place and want a single refresh without triggering unrelated state changes.

---

## Persistence

Serialize and restore expansion/selection state (not business data):

```dart
// Save
final json = controller.toJson();
prefs.setString('tree_state', jsonEncode(json));

// Restore
final saved = jsonDecode(prefs.getString('tree_state') ?? '{}');
controller.fromJson(saved as Map<String, Object?>);
```

The payload stores:

```json
{
  "version": 1,
  "expandedNodeIds": ["node-1", "node-3"],
  "selectedNodeIds": ["node-2"],
  "anchorNodeId": "node-2"
}
```

Unknown or stale IDs are silently ignored.

---

## Integrity guards

The controller enforces two invariants:

| Issue | What triggers it |
|-------|-----------------|
| `duplicateId` | Adding a node whose ID is already in the tree |
| `circularReference` | Adding a node as its own ancestor |

When a guard fires, the operation is **rejected** (no mutation) and a `TreeIntegrityIssue` is recorded:

```dart
controller.lastIntegrityIssue;                       // most recent issue
controller.integrityIssuesByNodeId;                  // per-node map
controller.getIntegrityIssueForNode('node-id');      // for one node
controller.clearIntegrityIssues();                   // reset
```

A `debugPrint` is also emitted so you can see integrity failures in the Flutter console during development.

---

## Async / lazy loading

```dart
controller.canNodeLoadChildren(node);            // true if node should load
controller.isNodeLoading('node-id');             // bool
controller.hasNodeLoadError('node-id');          // bool
controller.getNodeLoadError('node-id');          // Object?
controller.getNodeState('node-id');              // TreeNodeState
controller.getNodeAsyncState('node-id');         // TreeNodeAsyncState snapshot
controller.clearNodeLoadError('node-id');        // reset to idle

await controller.ensureNodeChildrenLoaded(node); // trigger loading
```

See [Async / Lazy Loading](Async-Lazy-Loading) for a complete guide.

---

## Sort

```dart
// Set or update the comparator at any time
controller.sortComparator = (a, b) => a.data.name.compareTo(b.data.name);

// Remove sorting
controller.sortComparator = null;
```

Changing the comparator triggers an immediate re-sort and UI update.

---

## Context menu node tracking

The controller remembers which node has an open context menu so the row stays highlighted while the overlay is visible:

```dart
controller.contextMenuNodeId;               // current value
controller.setContextMenuNodeId('node-id'); // set
controller.setContextMenuNodeId(null);      // clear
```

---

## See also

- [TreeNode](TreeNode) — the node model
- [SuperTreeView](SuperTreeView) — the rendering widget
- [Search & Filtering](Search-and-Filtering) — `TreeSearchController` and `FuzzyTreeFilter`
- [Async / Lazy Loading](Async-Lazy-Loading) — loading children on demand
- [Drag and Drop](Drag-and-Drop) — drop validation and `moveNodes`
