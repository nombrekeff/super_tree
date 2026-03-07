# Super Tree

A high-performance, fully customizable, and platform-agnostic hierarchical tree view for Flutter.

Build complex tree structures like **File Explorers**, **Todo Lists**, or **Permission Trees** with ease.

## Key Features

- **High Performance**: Uses a flat-list architecture internally for smooth scrolling with large trees.
- **Fully Customizable**: Control rendering with builders for expansion, prefix, content, and trailing actions.
- **Desktop and Mobile Ready**: Built-in support for keyboard navigation, right-click/long-press menus, and drag-and-drop.
- **State Management**: Optional `TreeController` for expansion, selection, filtering, and runtime updates.
- **Prebuilt Widgets**: Includes ready-to-use implementations for file-system and todo scenarios.
- **Search and Selection**: Supports fuzzy search and multi-selection workflows.
- **Testable**: Business logic is decoupled from UI for focused unit and widget testing.

## Getting Started

Add `super_tree` to your `pubspec.yaml`:

```yaml
dependencies:
  super_tree: ^0.1.0
```

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

For dynamic updates and interaction handling, use the `TreeController`:

```dart
final controller = TreeController<MyData>(
  roots: initialRoots,
  onNodeRenamed: (node, newName) => print('Renamed to $newName'),
);

// Toggle programmatically
controller.expandAll();
controller.addRoot(newNode);
```

## Examples

Check the [example project](example/lib/main.dart) for comprehensive demonstrations including:

- **File System Explorer**: VS Code style implementation with themes and icons.
- **Todo List**: Hierarchical task management with checkboxes.
- **Checkbox States**: Stateful checkbox behavior and parent-child tree workflows.
- **Responsive Menus**: Adaptive interaction patterns for Mobile and Desktop.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## License

MIT
