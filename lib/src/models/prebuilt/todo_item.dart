import 'package:super_tree/src/models/super_tree_data.dart';

/// A prebuilt data item representing a generic todo task.
class TodoItem with SuperTreeData {
  String title;
  bool isCompleted;
  
  TodoItem(this.title, {this.isCompleted = false});

  /// Allows todos to have sub-todos.
  @override
  bool get canHaveChildren => true;
}
