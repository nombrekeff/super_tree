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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complex Node UI Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SuperTreeView<TaskItem>(
              controller: _controller,
              style: TreeViewStyle(
                indentAmount: 32.0,
                selectedColor: Colors.blue.withValues(alpha: 0.1),
                hoverColor: Colors.grey.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              ),
              logic: const TreeViewConfig(
                expansionTrigger: ExpansionTrigger.tap,
              ),
              prefixBuilder: (context, node) {
                if (node.children.isEmpty) return const SizedBox(width: 24);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    node.isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: Colors.grey,
                  ),
                );
              },
              contentBuilder: (context, node, renameField) {
                final data = node.data;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
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
                        child: renameField ?? Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: node.children.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            decoration: data.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                            color: data.status == TaskStatus.done ? Colors.grey : Colors.black87,
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
                        backgroundColor: Colors.blueGrey[100],
                        child: Text(
                          data.assignee[0],
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      // More actions menu
                      const Icon(Icons.more_vert, size: 20, color: Colors.grey),
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
