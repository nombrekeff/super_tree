import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

class TodoListExample extends StatefulWidget {
  const TodoListExample({super.key});

  @override
  State<TodoListExample> createState() => _TodoListExampleState();
}

class _TodoListExampleState extends State<TodoListExample> {
  late final TreeController<TodoItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<TodoItem>(
      roots: [
        TreeNode(
          data: TodoItem('Work Tasks'),
          isExpanded: true,
          children: [
            TreeNode(
              data: TodoItem('Review PRs', isCompleted: true),
            ),
            TreeNode(
              data: TodoItem('Write Documentation'),
              children: [
                TreeNode(
                  data: TodoItem('Update README'),
                ),
                TreeNode(
                  data: TodoItem('Add inline comments', isCompleted: true),
                ),
              ],
              isExpanded: true,
            ),
            TreeNode(
              data: TodoItem('Fix issue #42'),
            ),
          ],
        ),
        TreeNode(
          data: TodoItem('Personal'),
          isExpanded: true,
          children: [
            TreeNode(
              data: TodoItem('Buy groceries'),
              children: [
                TreeNode(data: TodoItem('Milk')),
                TreeNode(data: TodoItem('Eggs')),
                TreeNode(data: TodoItem('Bread', isCompleted: true)),
              ],
              isExpanded: true,
            ),
            TreeNode(
              data: TodoItem('Call mom'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List Tree'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-sort Tree',
            onPressed: () {
              // Trigger a rebuild
              setState(() {});
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: TodoListSuperTree(
              controller: _controller,
              style: const TreeViewStyle(
                indentAmount: 24.0,
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              ),
              logic: const TreeViewConfig(
                enableDragAndDrop: true,
                expansionTrigger: ExpansionTrigger.tap,
              ),
              onTodoChanged: (item) {
                // We call setState so the checkbox visuals update.
                // Depending on the implementation, you could also manually call _controller.rebuild()
                // to force immediate visual re-sorting of the tree if desired.
                setState(() {});
              },
              contextMenuBuilder: (context, node) {
                return [
                  ContextMenuItem(
                    child: const Text('Delete'),
                    onTap: () {
                      _controller.removeNode(node);
                    },
                  ),
                ];
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checklist,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Todo List Example',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try checking off items to see them strike through.\n'
                        'Drag and drop items to reorganize your tasks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
