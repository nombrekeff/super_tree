import 'package:flutter/material.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Accessibility wrapper that standardizes tree-node semantics metadata.
class SuperTreeNodeSemantics<T> extends StatelessWidget {
  const SuperTreeNodeSemantics({
    super.key,
    required this.node,
    required this.canExpand,
    required this.isSelected,
    this.labelProvider,
    required this.child,
  });

  final TreeNode<T> node;
  final bool canExpand;
  final bool isSelected;
  final String Function(T data)? labelProvider;
  final Widget child;

  String _resolveNodeName() {
    final String rawName = labelProvider?.call(node.data) ?? node.data.toString();
    final String normalized = rawName.trim();
    if (normalized.isEmpty) {
      return 'Unnamed node';
    }
    return normalized;
  }

  String _buildLabel() {
    final String nodeName = _resolveNodeName();
    final int displayDepth = node.depth + 1;
    final String expansionState = canExpand
        ? (node.isExpanded ? 'Expanded' : 'Collapsed')
        : 'Leaf';
    final String selectionState = isSelected ? 'Selected' : 'Not selected';
    return '$nodeName, Depth $displayDepth, $expansionState, $selectionState';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key('tree_node_semantics_${node.id}'),
      container: true,
      label: _buildLabel(),
      selected: isSelected,
      expanded: canExpand ? node.isExpanded : null,
      child: child,
    );
  }
}
