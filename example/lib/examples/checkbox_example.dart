import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

class PermissionItem {
  final String title;
  bool isSelected;

  PermissionItem(this.title, {this.isSelected = false});
}

class CheckboxExample extends StatefulWidget {
  const CheckboxExample({super.key});

  @override
  State<CheckboxExample> createState() => _CheckboxExampleState();
}

class _CheckboxExampleState extends State<CheckboxExample> {
  late TreeController<PermissionItem> _controller;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<PermissionItem>(
      roots: [
        TreeNode(
          id: 'admin',
          data: PermissionItem('Administrator Access'),
          isExpanded: true,
          children: [
            TreeNode(
              id: 'users',
              data: PermissionItem('Manage Users'),
              isExpanded: true,
              children: [
                TreeNode(id: 'users_read', data: PermissionItem('Read Users')),
                TreeNode(id: 'users_write', data: PermissionItem('Create/Edit Users')),
                TreeNode(id: 'users_delete', data: PermissionItem('Delete Users')),
              ],
            ),
            TreeNode(
              id: 'settings',
              data: PermissionItem('System Settings'),
              children: [
                TreeNode(id: 'settings_view', data: PermissionItem('View Settings')),
                TreeNode(id: 'settings_edit', data: PermissionItem('Edit Settings')),
              ],
            ),
          ],
        ),
        TreeNode(
          id: 'finance',
          data: PermissionItem('Financial Records'),
          children: [
            TreeNode(id: 'finance_read', data: PermissionItem('View Reports')),
            TreeNode(id: 'finance_write', data: PermissionItem('Edit Records')),
          ],
        ),
      ],
    );
  }

  void _toggleNodeSelection(TreeNode<PermissionItem> node, bool? value) {
    if (value == null) return;
    
    setState(() {
      _setSelectionRecursive(node, value);
      _updateParentSelectionState(node);
    });
  }

  void _setSelectionRecursive(TreeNode<PermissionItem> node, bool value) {
    node.data.isSelected = value;
    for (var child in node.children) {
      _setSelectionRecursive(child, value);
    }
  }

  void _updateParentSelectionState(TreeNode<PermissionItem> node) {
    var parent = node.parent;
    while (parent != null) {
      bool allSelected = true;
      
      for (var child in parent.children) {
        if (!child.data.isSelected) {
          allSelected = false;
        }
      }
      
      parent.data.isSelected = allSelected;
      // In a real tristate implementation, we'd handle 'anySelected' differently.
      // For simplicity here, parent is selected only if ALL children are selected.
      
      parent = parent.parent;
    }
  }

  bool? _getCheckboxState(TreeNode<PermissionItem> node) {
    if (node.children.isEmpty) {
      return node.data.isSelected;
    }
    
    int selectedCount = 0;
    for (var child in node.children) {
      if (child.data.isSelected) selectedCount++;
    }
    
    if (selectedCount == 0) return false;
    if (selectedCount == node.children.length) return true;
    return null; // Tristate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkbox Tree Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.unfold_more),
            onPressed: () => _controller.expandAll(),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            onPressed: () => _controller.collapseAll(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: const Text(
                  'Role Permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SuperTreeView<PermissionItem>(
                  controller: _controller,
                  style: const TreeViewStyle(
                    indentAmount: 24.0,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  logic: const TreeViewLogic(
                    expansionTrigger: ExpansionTrigger.tap,
                  ),
                  prefixBuilder: (context, node) {
                    if (node.children.isEmpty) return const SizedBox(width: 28);
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: AnimatedRotation(
                        turns: node.isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right, size: 24),
                      ),
                    );
                  },
                  contentBuilder: (context, node, renameField) {
                    return Row(
                      children: [
                        Checkbox(
                          value: _getCheckboxState(node),
                          tristate: node.children.isNotEmpty,
                          onChanged: (val) => _toggleNodeSelection(node, val ?? false),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: renameField ?? Text(
                            node.data.title,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontWeight: node.children.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
