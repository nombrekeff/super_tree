import 'package:flutter/foundation.dart';
import '../models/tree_node.dart';

/// Manages the state and structure of the tree.
/// 
/// The [TreeController] is independent of the UI and provides methods to
/// expand, collapse, add, remove, and traverse nodes. It calculates and caches
/// a flat list of visible nodes [flatVisibleNodes] to be efficiently consumed
/// by a `ListView.builder` in the UI layer.
class TreeController<T> extends ChangeNotifier {
  final List<TreeNode<T>> _roots;

  /// Cache of the flat visible nodes computed from the current tree state.
  final List<TreeNode<T>> _flatVisibleNodes = [];

  /// Creates a new [TreeController] initialized with optional [roots].
  TreeController({
    List<TreeNode<T>>? roots,
  }) : _roots = roots ?? <TreeNode<T>>[] {
    _rebuildFlatList();
  }

  /// Returns the unmodifiable list of root nodes.
  List<TreeNode<T>> get roots => List.unmodifiable(_roots);

  /// Returns the flat list of currently visible (expanded) nodes.
  /// This list is pre-calculated and highly efficient for `ListView.builder`.
  List<TreeNode<T>> get flatVisibleNodes => List.unmodifiable(_flatVisibleNodes);

  /// Re-calculates the flat visible lists using Depth First Traversal.
  void _rebuildFlatList() {
    _flatVisibleNodes.clear();
    for (var root in _roots) {
      _flattenNode(root);
    }
  }

  void _flattenNode(TreeNode<T> node) {
    _flatVisibleNodes.add(node);
    if (node.isExpanded) {
      for (var child in node.children) {
        _flattenNode(child);
      }
    }
  }

  /// Expands a specific node and updates the UI.
  void expandNode(TreeNode<T> node) {
    if (!node.isExpanded) {
      node.isExpanded = true;
      _rebuildFlatList();
      notifyListeners();
    }
  }

  /// Collapses a specific node and updates the UI.
  void collapseNode(TreeNode<T> node) {
    if (node.isExpanded) {
      node.isExpanded = false;
      _rebuildFlatList();
      notifyListeners();
    }
  }

  /// Toggles the expansion state of a specific node.
  void toggleNodeExpansion(TreeNode<T> node) {
    if (node.isExpanded) {
      collapseNode(node);
    } else {
      expandNode(node);
    }
  }

  /// Expands all nodes in the tree recursively.
  void expandAll() {
    bool changed = false;
    void expandRecursive(TreeNode<T> n) {
      if (!n.isExpanded && n.hasChildren) {
        n.isExpanded = true;
        changed = true;
      }
      for (var child in n.children) {
        expandRecursive(child);
      }
    }

    for (var root in _roots) {
      expandRecursive(root);
    }

    if (changed) {
      _rebuildFlatList();
      notifyListeners();
    }
  }

  /// Collapses all nodes in the tree recursively.
  void collapseAll() {
    bool changed = false;
    void collapseRecursive(TreeNode<T> n) {
      if (n.isExpanded) {
        n.isExpanded = false;
        changed = true;
      }
      for (var child in n.children) {
        collapseRecursive(child);
      }
    }

    for (var root in _roots) {
      collapseRecursive(root);
    }

    if (changed) {
      _rebuildFlatList();
      notifyListeners();
    }
  }

  /// Adds a new root node to the tree.
  void addRoot(TreeNode<T> node) {
    _roots.add(node);
    _rebuildFlatList();
    notifyListeners();
  }

  /// Appends a child to a specific parent node.
  void addChild(TreeNode<T> parent, TreeNode<T> child) {
    parent.internalAddChild(child);
    if (parent.isExpanded) {
      _rebuildFlatList();
    }
    notifyListeners();
  }

  /// Removes a node from the tree entirely.
  void removeNode(TreeNode<T> node) {
    if (node.isRoot) {
      _roots.remove(node);
    } else {
      node.parent?.internalRemoveChild(node);
    }
    _rebuildFlatList();
    notifyListeners();
  }

  /// Moves a node from its current place to a specific position relative to a target node.
  void moveNode({
    required TreeNode<T> dragged, 
    required TreeNode<T> target, 
    required bool insertBefore,
    bool nestInside = false,
  }) {
    if (dragged.id == target.id) return;

    // First, detach from current parent
    removeNode(dragged);

    if (nestInside) {
      addChild(target, dragged);
      expandNode(target); // Auto expand to show the dropped child
    } else {
      final parent = target.parent;
      int index = 0;

      if (parent != null) {
        index = parent.children.indexOf(target);
        if (!insertBefore) index++;
        parent.internalInsertChild(index, dragged);
      } else {
        index = _roots.indexOf(target);
        if (!insertBefore) index++;
        _roots.insert(index, dragged);
      }
    }
    _rebuildFlatList();
    notifyListeners();
  }

  /// Finds a node by its ID using BFS. Returns null if not found.
  TreeNode<T>? findNodeById(String id) {
    final List<TreeNode<T>> queue = List.from(_roots);
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current.id == id) {
        return current;
      }
      queue.addAll(current.children);
    }
    return null;
  }
}
