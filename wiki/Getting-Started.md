# Getting Started

This page walks you through installing `super_tree` and building your first tree in just a few minutes.

## 1. Add the dependency

Add `super_tree` to your `pubspec.yaml`:

```yaml
dependencies:
  super_tree: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 2. Import the package

```dart
import 'package:super_tree/super_tree.dart';
```

## 3. Build your first tree

The minimal tree needs only two builders: `prefixBuilder` (the icon on the left) and `contentBuilder` (the label area).

```dart
SuperTreeView<String>(
  roots: [
    TreeNode(
      id: 'docs',
      data: 'Documents',
      isExpanded: true,
      children: [
        TreeNode(id: 'resume', data: 'Resume.pdf'),
        TreeNode(id: 'budget', data: 'Budget.xlsx'),
      ],
    ),
    TreeNode(
      id: 'pics',
      data: 'Pictures',
      children: [
        TreeNode(id: 'photo1', data: 'Vacation.jpg'),
      ],
    ),
  ],
  prefixBuilder: (context, node) => Icon(
    node.hasChildren ? Icons.folder : Icons.insert_drive_file,
  ),
  contentBuilder: (context, node, renameField) => Text(node.data),
)
```

That's it. Tapping a folder expands or collapses it automatically.

## 4. Add a controller for dynamic trees

Pass a `TreeController` when you need to manipulate the tree from outside the widget — programmatically expand nodes, add or remove items, respond to renames, and so on.

```dart
class _MyWidgetState extends State<MyWidget> {
  late final TreeController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<String>(
      roots: [
        TreeNode(id: 'root', data: 'Root', children: [
          TreeNode(id: 'child1', data: 'Child 1'),
          TreeNode(id: 'child2', data: 'Child 2'),
        ]),
      ],
      onNodeRenamed: (node, newName) {
        // persist the new name to your data layer
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // always dispose an external controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _controller.expandAll,
          child: const Text('Expand All'),
        ),
        Expanded(
          child: SuperTreeView<String>(
            controller: _controller,
            prefixBuilder: (context, node) =>
                Icon(node.hasChildren ? Icons.folder : Icons.insert_drive_file),
            contentBuilder: (context, node, renameField) => Text(node.data),
          ),
        ),
      ],
    );
  }
}
```

> **Tip:** When you provide your own `controller`, the widget does **not** dispose it. Call `_controller.dispose()` yourself in `State.dispose()`.

## 5. Customize appearance

Use `TreeViewStyle` to control colors, indentation, and padding:

```dart
SuperTreeView<String>(
  roots: myRoots,
  style: const TreeViewStyle(
    indentAmount: 20.0,
    selectedColor: Color(0xFF0078D4), // blue highlight
    hoverColor: Color(0x1A0078D4),
  ),
  prefixBuilder: (context, node) => const Icon(Icons.circle, size: 8),
  contentBuilder: (context, node, renameField) => Text(node.data),
)
```

## 6. Change interaction behavior

Use `TreeViewConfig` to change how users interact with the tree:

```dart
SuperTreeView<String>(
  roots: myRoots,
  logic: const TreeViewConfig(
    expansionTrigger: ExpansionTrigger.iconTap, // only the caret expands
    selectionMode: SelectionMode.multiple,       // Ctrl/Shift multi-select
    enableDragAndDrop: false,                    // disable drag-and-drop
  ),
  prefixBuilder: (context, node) => const Icon(Icons.folder),
  contentBuilder: (context, node, renameField) => Text(node.data),
)
```

## What's next?

| Topic | Where to go |
|-------|-------------|
| Full widget API | [SuperTreeView](SuperTreeView) |
| Working with nodes | [TreeNode](TreeNode) |
| Controller deep dive | [TreeController](TreeController) |
| Styling & behavior | [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) |
| Search | [Search & Filtering](Search-and-Filtering) |
| File explorer / todo list | [Prebuilt Widgets](Prebuilt-Widgets) |
| Drag and drop | [Drag and Drop](Drag-and-Drop) |
| Lazy loading | [Async / Lazy Loading](Async-Lazy-Loading) |
