# SuperTreeView

`SuperTreeView<T>` is the main widget that renders the tree. It listens to a `TreeController` and displays nodes in a highly efficient flat `ListView`.

## Constructors

### `SuperTreeView(…)` — standard

```dart
SuperTreeView<T>({
  Key? key,
  TreeController<T>? controller,
  List<TreeNode<T>>? roots,
  int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator,
  required Widget Function(BuildContext, TreeNode<T>) prefixBuilder,
  required Widget Function(BuildContext, TreeNode<T>, Widget? renameField) contentBuilder,
  Widget Function(BuildContext, TreeNode<T>)? expansionBuilder,
  Widget Function(BuildContext, TreeNode<T>)? loadingExpansionBuilder,
  double expansionSlotSize = 20,
  TreeLabelProvider<T>? labelProvider,
  Widget Function(BuildContext, TreeNode<T>)? trailingBuilder,
  List<ContextMenuItem> Function(BuildContext, TreeNode<T>)? contextMenuBuilder,
  List<ContextMenuItem> Function(BuildContext)? rootContextMenuBuilder,
  ScrollController? scrollController,
  ScrollPhysics? physics,
  TreeViewStyle style = const TreeViewStyle(),
  TreeViewConfig<T> logic = const TreeViewConfig(),
})
```

### `SuperTreeView.separated(…)` — with dividers

Wraps the list in a `ListView.separated`, injecting a divider widget between every node row.

```dart
SuperTreeView.separated<T>(
  // all standard properties, plus:
  required Widget Function(BuildContext, int) separatorBuilder,
  ...
)
```

## Required builders

### `prefixBuilder`

Builds the leading widget of every node row (e.g. a file/folder icon). Receives `BuildContext` and the `TreeNode<T>`.

```dart
prefixBuilder: (context, node) => Icon(
  node.hasChildren ? Icons.folder : Icons.insert_drive_file,
),
```

### `contentBuilder`

Builds the main content area. The third parameter `renameField` is non-null when the node is in rename mode — display it instead of the normal label.

```dart
contentBuilder: (context, node, renameField) {
  if (renameField != null) return renameField;
  return Text(node.data.name);
},
```

## Optional builders

### `expansionBuilder`

Replaces the default caret icon with a custom widget.

```dart
expansionBuilder: (context, node) => AnimatedRotation(
  turns: node.isExpanded ? 0.25 : 0,
  duration: const Duration(milliseconds: 150),
  child: const Icon(Icons.chevron_right),
),
```

### `loadingExpansionBuilder`

Shown instead of the expansion icon while a node is loading its children asynchronously. Defaults to a compact `CircularProgressIndicator`.

```dart
loadingExpansionBuilder: (context, node) =>
    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
```

### `expansionSlotSize`

Fixed width and height (in logical pixels) reserved for the expansion area. Keeping this stable prevents row-width jitter when switching between the caret and a loading indicator. Defaults to `20`.

### `trailingBuilder`

Builds an optional trailing widget, typically a context-menu button.

```dart
trailingBuilder: (context, node) => PopupMenuButton<String>(
  onSelected: (value) { /* handle action */ },
  itemBuilder: (_) => [
    const PopupMenuItem(value: 'delete', child: Text('Delete')),
  ],
),
```

### `contextMenuBuilder`

Called on right-click (desktop) or long-press (mobile) on a node. Return a list of `ContextMenuItem`s.

```dart
contextMenuBuilder: (context, node) => [
  ContextMenuItem(
    label: 'Rename',
    icon: Icons.edit,
    onTap: () => controller.setRenamingNodeId(node.id),
  ),
  ContextMenuItem(
    label: 'Delete',
    icon: Icons.delete,
    onTap: () => controller.removeNode(node),
  ),
],
```

### `rootContextMenuBuilder`

Same as `contextMenuBuilder` but triggered by right-clicking the tree background (outside any node). Useful for "New file" or "New folder" root-level actions.

```dart
rootContextMenuBuilder: (context) => [
  ContextMenuItem(
    label: 'New Folder',
    icon: Icons.create_new_folder,
    onTap: () => controller.createNewRoot(FolderItem('New Folder')),
  ),
],
```

### `labelProvider`

Extracts a `String` label from node data. Used as a fallback display value when no `contentBuilder` is given, and consumed internally by `TreeSearchController` for highlighted label rendering.

```dart
labelProvider: (data) => data.name,
```

## Controller vs. roots

You can provide the tree data in one of two ways:

| Approach | When to use |
|----------|-------------|
| `roots: [...]` | Static or rarely-changing tree. An internal `TreeController` is created automatically and disposed for you. |
| `controller: myController` | Dynamic tree that you need to mutate at runtime. You own the controller lifecycle — dispose it in `State.dispose()`. |

## Style & behavior

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `style` | `TreeViewStyle` | `const TreeViewStyle()` | Colors, indentation, padding — see [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) |
| `logic` | `TreeViewConfig<T>` | `const TreeViewConfig()` | Interaction behavior — see [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) |

## Scroll control

```dart
final _scrollController = ScrollController();

SuperTreeView<String>(
  scrollController: _scrollController,
  physics: const BouncingScrollPhysics(),
  ...
)
```

## Full example

```dart
class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  late final TreeController<FileItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileItem>(
      roots: _buildTree(),
      onNodeRenamed: (node, newName) {
        setState(() => node.data.name = newName);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SuperTreeView<FileItem>(
      controller: _controller,
      style: const TreeViewStyle(indentAmount: 20),
      logic: TreeViewConfig<FileItem>(
        expansionTrigger: ExpansionTrigger.iconTap,
        selectionMode: SelectionMode.single,
        namingStrategy: TreeNamingStrategy.doubleClick,
      ),
      prefixBuilder: (context, node) => Icon(
        node.data.isDirectory ? Icons.folder : Icons.insert_drive_file,
      ),
      contentBuilder: (context, node, renameField) {
        if (renameField != null) return renameField;
        return Text(node.data.name);
      },
      trailingBuilder: (context, node) => IconButton(
        icon: const Icon(Icons.more_vert, size: 16),
        onPressed: () { /* open menu */ },
      ),
      contextMenuBuilder: (context, node) => [
        ContextMenuItem(
          label: 'Rename',
          icon: Icons.edit,
          onTap: () => _controller.setRenamingNodeId(node.id),
        ),
        ContextMenuItem(
          label: 'Delete',
          icon: Icons.delete,
          onTap: () => _controller.removeNode(node),
        ),
      ],
    );
  }
}
```

## See also

- [TreeNode](TreeNode) — the data model
- [TreeController](TreeController) — programmatic tree manipulation
- [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) — all style and behavior options
- [Prebuilt Widgets](Prebuilt-Widgets) — drop-in file system and todo-list widgets
