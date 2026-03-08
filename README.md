# Super Tree [![](https://img.shields.io/pub/v/super_tree)](https://pub.dev/packages/super_tree) 

<a href="https://github.com/nombrekeff/super_tree/blob/main/assets/screenshots/demo_tree.png">
  <img src="https://raw.githubusercontent.com/nombrekeff/super_tree/main/assets/screenshots/demo_tree.png" alt="Demo tree preview" width="240" align="right" />
</a>

A high-performance, fully customizable, and platform-agnostic hierarchical tree view for Flutter.

Build complex tree structures like **File Explorers**, **Todo Lists**, or **Permission Trees** with ease.

### Key Features

- **High Performance**: Flat-list architecture for smooth scrolling.
- **Fully Customizable**: Builders and styling.
- **Desktop and Mobile Ready**: Keyboard nav, context menus, drag-and-drop.
- **State Management**: Optional controller for expansion, selection, updates.
- **Prebuilt Widgets**: Ready-to-use file-system and todo trees.
- **Search and Selection**: Fuzzy search and multi-selection.

### Getting Started

Add `super_tree` to your `pubspec.yaml`:

```yaml
dependencies:
  super_tree: ^0.2.1
```

```sh
flutter pub add super_tree
```

<br clear="right" />

## Usage

### Simple Tree View

Building a tree is as simple as providing a list of nodes:

```dart
import 'package:super_tree/super_tree.dart';

SuperTreeView<String>(
  roots: [
    TreeNode(
      id: 'root',
      data: 'Documents',
      children: [
        TreeNode(id: 'child1', data: 'Resume.pdf'),
        TreeNode(id: 'child2', data: 'Budget.xlsx'),
      ],
    ),
  ],
  prefixBuilder: (context, node) => Icon(
    node.hasChildren ? Icons.folder : Icons.insert_drive_file,
  ),
  contentBuilder: (context, node, renameField) => Text(node.data),
)
```

### Advanced Usage with Controller

For dynamic updates and interaction handling, use `TreeController<T>`:

```dart
final controller = TreeController<MyData>(
  roots: initialRoots,
  onNodeRenamed: (node, newName) => print('Renamed to $newName'),
);

// Toggle programmatically
controller.expandAll();
controller.addRoot(newNode);

controller.search("query");
```

### Preview Gallery

Current in-repo previews:

<table>
  <tr>
    <td align="center"><strong><a href="example/lib/examples/file_system_example.dart">File System Explorer + Search</a></strong><br><a href="https://github.com/nombrekeff/super_tree/blob/main/assets/screenshots/file-system-search-macos.png"><img src="https://raw.githubusercontent.com/nombrekeff/super_tree/main/assets/screenshots/file-system-search-macos.png" alt="File System Explorer with search active" width="360" /></a></td>
    <td align="center"><strong><a href="example/lib/examples/checkbox_example.dart">Checkbox State</a></strong><br><a href="https://github.com/nombrekeff/super_tree/blob/main/assets/screenshots/checkbox-state-macos.png"><img src="https://raw.githubusercontent.com/nombrekeff/super_tree/main/assets/screenshots/checkbox-state-macos.png" alt="Checkbox state example on macOS desktop layout" width="360" /></a></td>
  </tr>
  <tr>
    <td align="center"><strong><a href="example/lib/examples/complex_node_example.dart">Complex Node UI</a></strong><br><a href="https://github.com/nombrekeff/super_tree/blob/main/assets/screenshots/complex-node-ui-macos.png"><img src="https://raw.githubusercontent.com/nombrekeff/super_tree/main/assets/screenshots/complex-node-ui-macos.png" alt="Complex node UI example on macOS desktop layout" width="360" /></a></td>
    <td align="center"><strong><a href="example/lib/examples/todo_list_example.dart">Todo Tree</a></strong><br><a href="https://github.com/nombrekeff/super_tree/blob/main/assets/screenshots/todo-tree-macos.png"><img src="https://raw.githubusercontent.com/nombrekeff/super_tree/main/assets/screenshots/todo-tree-macos.png" alt="Todo tree example on macOS desktop layout" width="360" /></a></td>
  </tr>
  <tr>
    <td align="center"><strong><a href="example/lib/examples/simple_file_system_example.dart">Minimal File System</a></strong><br><a href="https://github.com/nombrekeff/super_tree/blob/main/assets/screenshots/minimal-file-system-macos.png"><img src="https://raw.githubusercontent.com/nombrekeff/super_tree/main/assets/screenshots/minimal-file-system-macos.png" alt="Minimal file system example on macOS desktop layout" width="360" /></a></td>
    <td align="center"></td>
  </tr>
</table>


Notes:
- Screenshot generation uses `flutter test --update-goldens` in `example/test/generate_previews_test.dart`.
- GIF creation is optional and requires `ffmpeg`.
- Canonical screenshot assets are stored in `assets/screenshots/` and committed to the repo.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## License

MIT
