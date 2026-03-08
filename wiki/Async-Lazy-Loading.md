# Async / Lazy Loading

Lazy loading lets child nodes be fetched asynchronously the first time a node is expanded. This keeps the initial tree fast — even when data comes from a network or database — and avoids loading data that users never open.

---

## How it works

1. Mark a node with `canLoadChildren: true` and leave `children` empty.
2. Provide a `loadChildren` callback to `TreeController`.
3. When the user first expands the node, `ensureNodeChildrenLoaded` is called automatically.
4. The node transitions through `idle → loading → loaded` (or `error`).
5. On success, the returned children are added and the tree refreshes.
6. On failure, the node enters the `error` state with the thrown object in `loadError`.

---

## Setup

### 1. Create nodes with `canLoadChildren: true`

```dart
TreeNode<FileSystemItem>(
  id: 'workspace',
  data: FolderItem('workspace'),
  isExpanded: false,
  canLoadChildren: true, // marks this node as lazily loadable
)
```

Leave `children` empty — the expansion caret is shown anyway because `canLoadChildren` is `true`.

### 2. Provide the `loadChildren` callback

```dart
final controller = TreeController<FileSystemItem>(
  roots: [
    TreeNode(
      id: 'root',
      data: FolderItem('root'),
      canLoadChildren: true,
    ),
  ],
  loadChildren: (node) async {
    // Fetch from network, database, etc.
    final items = await myApi.listChildren(node.data.path);
    return items.map((item) => TreeNode(
      id: item.id,
      data: item.isDirectory
          ? FolderItem(item.name)
          : FileItem(item.name),
      canLoadChildren: item.isDirectory, // nested lazy loading
    )).toList();
  },
);
```

Each returned node can itself have `canLoadChildren: true` for recursive lazy loading.

---

## Loading and error states

The `TreeNodeState` enum tracks the async lifecycle:

| State | Meaning |
|-------|---------|
| `idle` | Ready to load — expansion shows the caret |
| `loading` | Currently fetching children |
| `loaded` | Children have been fetched (or there were none to fetch) |
| `error` | Last load attempt threw an exception |

Access the state programmatically:

```dart
controller.getNodeState('node-id');         // TreeNodeState
controller.isNodeLoading('node-id');        // bool
controller.hasNodeLoadError('node-id');     // bool
controller.getNodeLoadError('node-id');     // Object?
controller.getNodeAsyncState('node-id');    // TreeNodeAsyncState snapshot
```

---

## Custom loading indicator

By default, a compact `CircularProgressIndicator` is shown in the expansion slot while loading. Override it with `loadingExpansionBuilder`:

```dart
SuperTreeView<FileSystemItem>(
  controller: controller,
  loadingExpansionBuilder: (context, node) => SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(
      strokeWidth: 1.5,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
  expansionSlotSize: 20, // keep the slot size stable to avoid layout jitter
  ...
)
```

---

## Handling errors in the UI

When `nodeState == TreeNodeState.error`, you can show an error indicator. A common pattern is to put a retry button in the trailing area or context menu:

```dart
SuperTreeView<FileSystemItem>(
  controller: controller,
  trailingBuilder: (context, node) {
    if (!controller.hasNodeLoadError(node.id)) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
      tooltip: 'Retry',
      onPressed: () {
        controller.clearNodeLoadError(node.id);
        controller.toggleNodeExpansion(node);
      },
    );
  },
  ...
)
```

Alternatively, listen to the controller and show a `SnackBar`:

```dart
controller.addListener(() {
  if (controller.hasNodeLoadError('my-node')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load: ${controller.getNodeLoadError('my-node')}')),
    );
  }
});
```

---

## Clearing errors and retrying

```dart
controller.clearNodeLoadError('node-id');
// The node returns to idle state — expanding it triggers a fresh load
```

---

## Simulated delay example

The following snippet mirrors the pattern used in the example app:

```dart
Future<List<TreeNode<FileSystemItem>>> _loadChildren(
  TreeNode<FileSystemItem> node,
) async {
  await Future.delayed(const Duration(milliseconds: 800)); // simulate network

  switch (node.id) {
    case 'root':
      return [
        TreeNode(id: 'lib', data: FolderItem('lib'), canLoadChildren: true),
        TreeNode(id: 'pubspec', data: FileItem('pubspec.yaml')),
      ];
    case 'lib':
      return [
        TreeNode(id: 'main', data: FileItem('main.dart')),
      ];
    default:
      return [];
  }
}
```

---

## Edge cases

| Scenario | Behaviour |
|----------|-----------|
| Node already has children | `canNodeLoadChildren` returns `false`; `loadChildren` is never called |
| Node is expanded while loading | The second expand call is a no-op — the loading is already in progress |
| `loadChildren` returns duplicate IDs | The controller rejects the batch, sets the node to `error`, and records a `TreeIntegrityIssue` |
| Tree is disposed before load completes | The stale result is silently discarded (node lookup returns `null`) |

---

## See also

- [TreeController](TreeController) — `ensureNodeChildrenLoaded`, integrity guards
- [TreeNode](TreeNode) — `canLoadChildren`, `nodeState`, `loadError`
- [SuperTreeView](SuperTreeView) — `loadingExpansionBuilder` and `expansionSlotSize`
