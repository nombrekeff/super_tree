# Super Tree 🌳

A high-performance, fully customizable, and platform-agnostic hierarchical tree view for Flutter.

Build complex tree structures like **File Explorers**, **Todo Lists**, or **Permission Trees** with ease.

## Key Features

- ⚡ **High Performance**: Uses a flat list architecture internally for smooth scrolling even with thousands of nodes.
- 🎨 **Fully Customizable**: Control every pixel with builders for prefixes, content, and trailing actions.
- 🖱️ **Desktop & Mobile Ready**: Built-in support for context menus (right-click), long-press actions, and drag-and-drop.
- 🔄 **State Management**: Optional `TreeController` for granular control over expansion, selection, and updates.
- 📂 **Prebuilt Kits**: includes ready-to-use implementations for common use cases like File Systems and Todo Lists.
- 🔍 **Search & Selection**: Built-in methods for finding nodes and managing multi-selection.
- 🧪 **Testable**: Decoupled business logic from UI for easier unit testing.

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
- **Checkbox States**: Recursive parent/child checkbox synchronization.
- **Responsive Menus**: Adaptive interaction patterns for Mobile and Desktop.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## License

MIT
