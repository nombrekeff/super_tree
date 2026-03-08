# Prebuilt Widgets

`super_tree` ships two ready-to-use tree widgets that cover the most common use cases out of the box. Both are thin wrappers around `SuperTreeView` with sensible defaults that you can override at any level.

---

## FileSystemSuperTree

A file-explorer widget preconfigured for `FileSystemItem` data (folders and files).

### Data model

Use the included `FolderItem` and `FileItem` data classes, or extend `FileSystemItem` yourself:

```dart
// Provided by super_tree
abstract class FileSystemItem with SuperTreeData {
  String name;
  bool get isFolder;
}

class FolderItem extends FileSystemItem { ... } // canHaveChildren = true
class FileItem   extends FileSystemItem { ... } // canHaveChildren = false
```

Or create your own subclass:

```dart
class MyFile extends FileSystemItem {
  final String extension;
  MyFile(String name, {required this.extension}) : super(name);

  @override
  bool get isFolder => false;
}
```

### Basic usage

```dart
FileSystemSuperTree(
  roots: [
    TreeNode(
      data: FolderItem('lib'),
      isExpanded: true,
      children: [
        TreeNode(data: FileItem('main.dart')),
        TreeNode(data: FileItem('app.dart')),
      ],
    ),
    TreeNode(data: FileItem('pubspec.yaml')),
  ],
)
```

### With a controller

```dart
final controller = TreeController<FileSystemItem>(
  onNodeRenamed: (node, newName) {
    setState(() => node.data.name = newName);
  },
);

FileSystemSuperTree(
  controller: controller,
  logic: TreeViewConfig<FileSystemItem>(
    namingStrategy: TreeNamingStrategy.doubleClick,
    selectionMode: SelectionMode.single,
  ),
)
```

### All properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `controller` | `TreeController<FileSystemItem>?` | — | External controller |
| `roots` | `List<TreeNode<FileSystemItem>>?` | — | Seed nodes for the internal controller |
| `sortComparator` | `Comparator?` | — | Sort comparator |
| `style` | `TreeViewStyle` | default | Visual style |
| `logic` | `TreeViewConfig<FileSystemItem>` | default | Interaction config |
| `fileSystemTheme` | `FileSystemTreeTheme?` | — | File-system specific visual tokens |
| `iconProvider` | `FileSystemIconProvider?` | — | Maps file types to icons |
| `prefixBuilder` | builder | — | Override the prefix (icon) area |
| `contentBuilder` | builder | — | Override the label area |
| `trailingBuilder` | builder | — | Override the trailing area |
| `contextMenuBuilder` | builder | — | Node right-click / long-press menu |
| `rootContextMenuBuilder` | builder | — | Background right-click menu |
| `scrollController` | `ScrollController?` | — | External scroll controller |
| `physics` | `ScrollPhysics?` | — | Scroll physics |

### Theme presets

Apply a complete visual theme with one line:

```dart
final preset = SuperTreeThemes.vscode();     // dark VS Code look
// or SuperTreeThemes.material()            // Material Design
// or SuperTreeThemes.compact()             // Compact density

Theme(
  data: preset.toThemeData(),
  child: FileSystemSuperTree(
    fileSystemTheme: preset.fileSystemTheme,
    iconProvider: preset.fileSystemIconProvider,
    roots: myRoots,
  ),
)
```

`SuperTreeThemePreset` exposes:

| Property | Description |
|----------|-------------|
| `treeStyle` | `TreeViewStyle` for `SuperTreeView` |
| `fileSystemTheme` | File-system visual tokens |
| `fileSystemIconProvider` | Icon mapping |
| `sidebarColor` | Suggested sidebar background |
| `brightness` | `Brightness.dark` or `Brightness.light` |
| `scaffoldBackgroundColor` | Suggested scaffold background |
| `surfaceColor` | Suggested card/app-bar color |
| `primaryColor` | Optional accent color |

---

## TodoListSuperTree

A todo-list widget preconfigured for `TodoItem` data. Shows checkboxes out of the box and sorts uncompleted items before completed ones by default.

### Data model

```dart
// Provided by super_tree
class TodoItem with SuperTreeData {
  String title;
  bool isCompleted;

  TodoItem(this.title, {this.isCompleted = false});

  @override
  bool get canHaveChildren => true; // supports nested sub-tasks
}
```

### Basic usage

```dart
TodoListSuperTree(
  roots: [
    TreeNode(
      data: TodoItem('Work tasks'),
      isExpanded: true,
      children: [
        TreeNode(data: TodoItem('Review PRs', isCompleted: true)),
        TreeNode(data: TodoItem('Write docs')),
      ],
    ),
  ],
  onTodoChanged: (item) {
    print('${item.title} is now ${item.isCompleted ? "done" : "pending"}');
  },
)
```

### With a controller and search

```dart
final controller = TreeController<TodoItem>(
  roots: myTodos,
  onNodeRenamed: (node, newName) => setState(() => node.data.title = newName),
);

final filter = FuzzyTreeFilter<TodoItem>(
  keywordRules: [
    TreeFilterKeywordRule<TodoItem>(
      keywords: {'done', 'completed'},
      predicate: (node) => node.data.isCompleted,
    ),
    TreeFilterKeywordRule<TodoItem>(
      keywords: {'open', 'pending'},
      predicate: (node) => !node.data.isCompleted,
    ),
  ],
);

final searchController = TreeSearchController<TodoItem>(
  treeController: controller,
  labelProvider: (item) => item.title,
  searchMatcher: filter.asSearchMatcher(),
);
```

### All properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `controller` | `TreeController<TodoItem>?` | — | External controller |
| `roots` | `List<TreeNode<TodoItem>>?` | — | Seed nodes |
| `sortComparator` | `Comparator?` | uncompleted first | Custom sort |
| `style` | `TreeViewStyle` | default | Visual style |
| `logic` | `TreeViewConfig<TodoItem>` | default | Interaction config |
| `onTodoChanged` | `void Function(TodoItem)?` | — | Called when a checkbox is toggled |
| `prefixBuilder` | builder | — | Override the checkbox area |
| `contentBuilder` | builder | — | Override the title area |
| `trailingBuilder` | builder | — | Override the trailing area |
| `contextMenuBuilder` | builder | — | Node right-click / long-press menu |
| `scrollController` | `ScrollController?` | — | External scroll controller |
| `physics` | `ScrollPhysics?` | — | Scroll physics |

---

## SuperTreeData mixin

Both `FileSystemItem` and `TodoItem` mix in `SuperTreeData`. When your data implements this mixin, `TreeController.addChild` checks `canHaveChildren` before adding:

```dart
class MyLeafNode with SuperTreeData {
  @override
  bool get canHaveChildren => false; // TreeController will reject addChild calls
}
```

---

## See also

- [SuperTreeView](SuperTreeView) — the underlying widget
- [TreeController](TreeController) — programmatic control
- [Search & Filtering](Search-and-Filtering) — adding fuzzy search to either widget
- [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) — styling and behavior
