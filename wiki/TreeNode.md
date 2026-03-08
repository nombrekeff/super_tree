# TreeNode

`TreeNode<T>` is the core data model of the tree. Each node holds your custom business data alongside metadata that drives the UI — expansion state, selection state, lazy-loading lifecycle, and parent/child relationships.

## Constructor

```dart
TreeNode<T>({
  String? id,              // auto-generated if omitted
  required T data,
  List<TreeNode<T>>? children,
  bool isExpanded = false,
  bool isSelected = false,
  bool canLoadChildren = false,
  TreeNodeState? nodeState,
  Object? loadError,
  bool isNew = false,
  TreeNode<T>? parent,
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | `String?` | auto-generated | Unique identifier — must be unique across the whole tree |
| `data` | `T` | required | Your business object |
| `children` | `List<TreeNode<T>>?` | `[]` | Initial child nodes |
| `isExpanded` | `bool` | `false` | Whether the node starts expanded |
| `isSelected` | `bool` | `false` | Whether the node starts selected |
| `canLoadChildren` | `bool` | `false` | Enables lazy-loading (see [Async / Lazy Loading](Async-Lazy-Loading)) |
| `nodeState` | `TreeNodeState?` | inferred | Override the initial loading lifecycle state |
| `loadError` | `Object?` | `null` | Pre-populate a loading error |
| `isNew` | `bool` | `false` | Marks a node as newly created (used by the rename flow) |
| `parent` | `TreeNode<T>?` | `null` | Normally set automatically by `TreeController` |

> **Important:** Node IDs must be unique across the entire tree. The `TreeController` enforces this and will reject any operation that would create a duplicate.

## Properties

### Read / write

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Node identifier |
| `isExpanded` | `bool` | Expansion state |
| `isSelected` | `bool` | Selection state |
| `canLoadChildren` | `bool` | Lazy-loading flag |
| `nodeState` | `TreeNodeState` | Current async lifecycle state |
| `loadError` | `Object?` | Last load error |
| `isNew` | `bool` | Newly-created flag |
| `parent` | `TreeNode<T>?` | Parent reference (managed by controller) |

### Read-only computed

| Getter | Type | Description |
|--------|------|-------------|
| `data` | `T` | The business object |
| `children` | `List<TreeNode<T>>` | Unmodifiable child list |
| `depth` | `int` | Distance from root (0 = root node) |
| `hasChildren` | `bool` | `true` when there are child nodes |
| `isRoot` | `bool` | `true` when `parent == null` |
| `isLeaf` | `bool` | `true` when there are no children |

## TreeNodeState

The lazy-loading lifecycle is tracked by the `TreeNodeState` enum:

| State | Meaning |
|-------|---------|
| `idle` | The node can load children but hasn't started yet |
| `loading` | Children are being fetched asynchronously |
| `loaded` | Children have been loaded (or the node has no lazy flag) |
| `error` | The last load attempt failed |

A node is in `idle` state when `canLoadChildren == true` and `children` is empty. Once children are fetched successfully it transitions to `loaded` and `canLoadChildren` is set to `false`.

## Building a node tree

```dart
final root = TreeNode<String>(
  id: 'root',
  data: 'My Project',
  isExpanded: true,
  children: [
    TreeNode(
      id: 'src',
      data: 'src',
      children: [
        TreeNode(id: 'main', data: 'main.dart'),
        TreeNode(id: 'app',  data: 'app.dart'),
      ],
    ),
    TreeNode(id: 'pubspec', data: 'pubspec.yaml'),
  ],
);
```

## copyWith

`copyWith` creates a deep copy of a node with optional field overrides. All children are also deep-copied.

```dart
final copy = originalNode.copyWith(isExpanded: true);
```

## Equality

Two `TreeNode` instances are considered equal when their `id` values match:

```dart
node1 == node2; // true when node1.id == node2.id
```

## Internal mutation methods

The methods below are intentionally prefixed with `internal` to signal that they are meant to be called only by `TreeController`. Calling them directly bypasses integrity checks and index updates.

| Method | Description |
|--------|-------------|
| `internalAddChild(child)` | Appends a child and sets its parent |
| `internalRemoveChild(child)` | Removes a child and clears its parent |
| `internalInsertChild(index, child)` | Inserts a child at a specific index |
| `internalSortChildren(comparator, {recursive})` | Sorts children in-place |

Always use the equivalent `TreeController` methods (`addChild`, `removeNode`, etc.) for safe mutations.

## See also

- [TreeController](TreeController) — managing node lifecycle from outside the widget
- [Async / Lazy Loading](Async-Lazy-Loading) — using `canLoadChildren` and `nodeState`
