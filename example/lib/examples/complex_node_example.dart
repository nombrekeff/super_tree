import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

class TaskItem {
  final String title;
  final String assignee;
  final TaskPriority priority;
  TaskStatus status;

  TaskItem({
    required this.title,
    required this.assignee,
    required this.priority,
    this.status = TaskStatus.todo,
  });
}

class ComplexNodeExample extends StatefulWidget {
  const ComplexNodeExample({super.key});

  @override
  State<ComplexNodeExample> createState() => _ComplexNodeExampleState();
}

class _ComplexNodeExampleState extends State<ComplexNodeExample> {
  late TreeController<TaskItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<TaskItem>(
      roots: [
        TreeNode(
          id: 'epic_1',
          data: TaskItem(
            title: 'Website Redesign',
            assignee: 'Alice',
            priority: TaskPriority.high,
            status: TaskStatus.inProgress,
          ),
          isExpanded: true,
          children: [
            TreeNode(
              id: 'story_1_1',
              data: TaskItem(
                title: 'Design Mockups',
                assignee: 'Bob',
                priority: TaskPriority.high,
                status: TaskStatus.done,
              ),
            ),
            TreeNode(
              id: 'story_1_2',
              data: TaskItem(
                title: 'Implement Header',
                assignee: 'Charlie',
                priority: TaskPriority.medium,
                status: TaskStatus.inProgress,
              ),
              isExpanded: true,
              children: [
                TreeNode(
                  id: 'task_1_2_1',
                  data: TaskItem(
                    title: 'Add Logo',
                    assignee: 'Charlie',
                    priority: TaskPriority.low,
                    status: TaskStatus.done,
                  ),
                ),
                TreeNode(
                  id: 'task_1_2_2',
                  data: TaskItem(
                    title: 'Navigation Menu',
                    assignee: 'Charlie',
                    priority: TaskPriority.high,
                    status: TaskStatus.todo,
                  ),
                ),
              ],
            ),
          ],
        ),
        TreeNode(
          id: 'epic_2',
          data: TaskItem(
            title: 'Q2 Marketing Campaign',
            assignee: 'Diana',
            priority: TaskPriority.medium,
          ),
          children: [
            TreeNode(
              id: 'story_2_1',
              data: TaskItem(
                title: 'Social Media Assets',
                assignee: 'Eve',
                priority: TaskPriority.medium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Complex Node UI Example')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SuperTreeView<TaskItem>(
              controller: _controller,
              style: TreeViewStyle(
                indentAmount: 32.0,
                selectedColor: scheme.secondaryContainer.withValues(alpha: 0.35),
                hoverColor: scheme.surfaceContainerHigh.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              ),
              logic: const TreeViewConfig(expansionTrigger: ExpansionTrigger.tap),
              prefixBuilder: (context, node) {
                if (node.children.isEmpty) return const SizedBox(width: 24);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    node.isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: scheme.onSurfaceVariant,
                  ),
                );
              },
              contentBuilder: (context, node, renameField) {
                final data = node.data;
                final Color titleColor = data.status == TaskStatus.done
                    ? scheme.onSurface.withValues(alpha: 0.6)
                    : scheme.onSurface;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Status Icon
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (data.status == TaskStatus.todo) {
                              data.status = TaskStatus.inProgress;
                            } else if (data.status == TaskStatus.inProgress) {
                              data.status = TaskStatus.done;
                            } else {
                              data.status = TaskStatus.todo;
                            }
                          });
                        },
                        child: Icon(
                          _getStatusIcon(data.status),
                          color: _getStatusColor(data.status),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title
                      Expanded(
                        child:
                            renameField ??
                            Text(
                              data.title,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: node.children.isNotEmpty
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                decoration: data.status == TaskStatus.done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: titleColor,
                              ),
                            ),
                      ),

                      // Priority Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(data.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(data.priority),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Assignee Avatar
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.secondaryContainer,
                        child: Text(
                          data.assignee[0],
                          style: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer),
                        ),
                      ),

                      const SizedBox(width: 8),
                      // More actions menu
                      Icon(Icons.more_vert, size: 20, color: scheme.onSurfaceVariant),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
