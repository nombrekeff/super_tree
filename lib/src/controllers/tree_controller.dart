import 'package:flutter/foundation.dart';
import '../models/tree_node.dart';
import '../models/super_tree_data.dart';

/// Manages the state and structure of the tree.
/// 
/// The [TreeController] is independent of the UI and provides methods to
/// expand, collapse, add, remove, and traverse nodes. It calculates and caches
/// a flat list of visible nodes [flatVisibleNodes] to be efficiently consumed
/// by a `ListView.builder` in the UI layer.
class TreeController<T> extends ChangeNotifier {
  final List<TreeNode<T>> _roots;
  
  /// Optional comparator to keep the tree sorted.
  int Function(TreeNode<T> a, TreeNode<T> b)? _sortComparator;

  /// Cache of the flat visible nodes computed from the current tree state.
  final List<TreeNode<T>> _flatVisibleNodes = [];

  /// Index for O(1) node lookup by ID.
  final Map<String, TreeNode<T>> _nodeIndex = {};

  /// Creates a new [TreeController] initialized with optional [roots].
  /// 
  /// [sortComparator] can be used to keep the tree automatically sorted.
  /// [onNodeRenamed] and [onNodeDeleted] are useful for listening to state changes
  /// triggered by high-level actions.
  TreeController({
    List<TreeNode<T>>? roots,
    int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator,
    this.onNodeRenamed,
    this.onNodeDeleted,
  }) : _roots = roots ?? <TreeNode<T>>[],
       _sortComparator = sortComparator {
    for (var root in _roots) {
      _indexNode(root);
    }
    _rebuildFlatList();
  }

  /// Callback generated when a node is renamed.
  final void Function(TreeNode<T> node, String newName)? onNodeRenamed;

  /// Callback generated when a node is deleted.
  final void Function(TreeNode<T> node)? onNodeDeleted;

  /// Gets the current sort comparator.
  int Function(TreeNode<T> a, TreeNode<T> b)? get sortComparator => _sortComparator;

  /// Sets the sort comparator and re-sorts the tree.
  set sortComparator(int Function(TreeNode<T> a, TreeNode<T> b)? comparator) {
    _sortComparator = comparator;
    if (_sortComparator != null) {
      _sortTree();
    }
    _rebuildFlatList();
    notifyListeners();
  }

  /// Sorts the tree based on the provided comparator.
  void _sortTree() {
    if (_sortComparator == null) return;
    _roots.sort(_sortComparator!);
    for (var root in _roots) {
      root.internalSortChildren(_sortComparator!, recursive: true);
    }
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

  /// Indexes a node and all its descendants recursively.
  void _indexNode(TreeNode<T> node) {
    String finalId = node.id;
    if (_nodeIndex.containsKey(finalId)) {
      final String msg = 'Duplicate node ID detected: "$finalId". All IDs in the tree must be unique.';
      
      // In debug mode, we want to be loud and fail fast.
      assert(false, '[SuperTree] FATAL: $msg');

      // In release mode, we mangle the ID to prevent breaking the tree logic (like expansion/selection index collisions).
      int suffix = 1;
      while (_nodeIndex.containsKey('${finalId}_dup_$suffix')) {
        suffix++;
      }
      finalId = '${finalId}_dup_$suffix';
      
      // We still log a warning in release mode so developers can see it in logs.
      debugPrint('[SuperTree] WARNING: $msg. Auto-mangled to "$finalId" to prevent state corruption.');
      
      // We update the node's ID to match the final unique ID.
      node.id = finalId;
    }
    
    _nodeIndex[finalId] = node;
    for (var child in node.children) {
      _indexNode(child);
    }
  }

  /// Unindexes a node and all its descendants recursively.
  void _unindexNode(TreeNode<T> node) {
    _nodeIndex.remove(node.id);
    for (var child in node.children) {
      _unindexNode(child);
    }
  }

  /// Expands a specific node and updates the UI.
  void expandNode(TreeNode<T> node) {
    if (!node.isExpanded) {
      node.isExpanded = true;
      
      // Delta update: Insert visible descendants
      final index = _flatVisibleNodes.indexOf(node);
      if (index != -1) {
        final descendants = <TreeNode<T>>[];
        for (var child in node.children) {
          _getVisibleDescendants(child, descendants);
        }
        _flatVisibleNodes.insertAll(index + 1, descendants);
      } else {
        // Fallback if node is not in flat list for some reason
        _rebuildFlatList();
      }
      
      notifyListeners();
    }
  }

  /// Collapses a specific node and updates the UI.
  void collapseNode(TreeNode<T> node) {
    if (node.isExpanded) {
      node.isExpanded = false;
      
      // Delta update: Remove visible descendants
      final index = _flatVisibleNodes.indexOf(node);
      if (index != -1) {
        final descendants = <TreeNode<T>>[];
        for (var child in node.children) {
          _getVisibleDescendants(child, descendants);
        }
        _flatVisibleNodes.removeRange(index + 1, index + 1 + descendants.length);
      } else {
        // Fallback
        _rebuildFlatList();
      }
      
      notifyListeners();
    }
  }

  /// Recursively gets all visible descendants of a node.
  void _getVisibleDescendants(TreeNode<T> node, List<TreeNode<T>> result) {
    result.add(node);
    if (node.isExpanded) {
      for (var child in node.children) {
        _getVisibleDescendants(child, result);
      }
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



  /// The node IDs that are currently selected.
  final Set<String> _selectedNodeIds = {};
  Set<String> get selectedNodeIds => Set.unmodifiable(_selectedNodeIds);

  /// Gets the first selected node ID, if any.
  String? get selectedNodeId => _selectedNodeIds.isEmpty ? null : _selectedNodeIds.first;

  /// Update the current selected node ID (single selection).
  void setSelectedNodeId(String? id) {
    _selectedNodeIds.clear();
    if (id != null) {
      _selectedNodeIds.add(id);
    }
    notifyListeners();
  }

  /// Toggles selection of a node.
  void toggleSelection(String id) {
    if (_selectedNodeIds.contains(id)) {
      _selectedNodeIds.remove(id);
    } else {
      _selectedNodeIds.add(id);
    }
    notifyListeners();
  }

  /// Selects a range of nodes from the last selected node to the target node.
  void selectRange(String targetId) {
    if (_flatVisibleNodes.isEmpty) return;
    
    final lastId = _selectedNodeIds.isNotEmpty ? _selectedNodeIds.last : _flatVisibleNodes.first.id;
    final startIndex = _flatVisibleNodes.indexWhere((n) => n.id == lastId);
    final endIndex = _flatVisibleNodes.indexWhere((n) => n.id == targetId);
    
    if (startIndex == -1 || endIndex == -1) return;
    
    final min = startIndex < endIndex ? startIndex : endIndex;
    final max = startIndex < endIndex ? endIndex : startIndex;
    
    for (int i = min; i <= max; i++) {
      _selectedNodeIds.add(_flatVisibleNodes[i].id);
    }
    notifyListeners();
  }

  /// Selects the next visible node in the flat list.
  void selectNext() {
    if (_flatVisibleNodes.isEmpty) return;
    final lastSelected = selectedNodeId;
    if (lastSelected == null) {
      setSelectedNodeId(_flatVisibleNodes.first.id);
      return;
    }

    final currentIndex = _flatVisibleNodes.indexWhere((n) => n.id == lastSelected);
    if (currentIndex != -1 && currentIndex < _flatVisibleNodes.length - 1) {
      setSelectedNodeId(_flatVisibleNodes[currentIndex + 1].id);
    }
  }

  /// Selects the previous visible node in the flat list.
  void selectPrevious() {
    if (_flatVisibleNodes.isEmpty) return;
    final lastSelected = selectedNodeId;
    if (lastSelected == null) {
      setSelectedNodeId(_flatVisibleNodes.last.id);
      return;
    }

    final currentIndex = _flatVisibleNodes.indexWhere((n) => n.id == lastSelected);
    if (currentIndex > 0) {
      setSelectedNodeId(_flatVisibleNodes[currentIndex - 1].id);
    }
  }

  /// Selects the first visible node.
  void selectFirst() {
    if (_flatVisibleNodes.isNotEmpty) {
      setSelectedNodeId(_flatVisibleNodes.first.id);
    }
  }

  /// Selects the last visible node.
  void selectLast() {
    if (_flatVisibleNodes.isNotEmpty) {
      setSelectedNodeId(_flatVisibleNodes.last.id);
    }
  }

  /// The node ID that currently has a context menu open for it, if any.
  /// Used by the UI to retain hover/focus styling while the menu is open.
  String? _contextMenuNodeId;
  String? get contextMenuNodeId => _contextMenuNodeId;

  /// Update the current context menu node ID directly.
  void setContextMenuNodeId(String? id) {
    if (_contextMenuNodeId != id) {
      _contextMenuNodeId = id;
      notifyListeners();
    }
  }

  /// The node ID that is currently being renamed, if any.
  String? _renamingNodeId;
  String? get renamingNodeId => _renamingNodeId;

  /// Update the current renaming node ID.
  void setRenamingNodeId(String? id) {
    if (_renamingNodeId != id) {
      _renamingNodeId = id;
      notifyListeners();
    }
  }

  /// Submits a rename action for a specific node.
  void renameNode(String id, String newName) {
    final node = findNodeById(id);
    if (node != null) {
      onNodeRenamed?.call(node, newName);
      setRenamingNodeId(null);
    }
  }

  /// Adds a new root node to the tree.
  void addRoot(TreeNode<T> node) {
    _indexNode(node);
    _roots.add(node);
    if (_sortComparator != null) {
      _roots.sort(_sortComparator!);
    }
    _rebuildFlatList();
    notifyListeners();
  }

  /// Appends a child to a specific parent node.
  void addChild(TreeNode<T> parent, TreeNode<T> child) {
    final parentData = parent.data;
    if (parentData is SuperTreeData && !parentData.canHaveChildren) {
      assert(false, 'Cannot add a child to a node that returns canHaveChildren = false');
      return;
    }
    _indexNode(child);
    parent.internalAddChild(child);
    if (_sortComparator != null) {
      parent.internalSortChildren(_sortComparator!);
    }
    if (parent.isExpanded) {
      _rebuildFlatList();
    }
    notifyListeners();
  }

  /// Removes a node from the tree entirely.
  void removeNode(TreeNode<T> node) {
    _unindexNode(node);
    if (node.isRoot) {
      _roots.remove(node);
    } else {
      node.parent?.internalRemoveChild(node);
    }
    onNodeDeleted?.call(node);
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

    // Preventive check: Cannot drop a node into its own descendant
    if (isDescendantOf(target.id, dragged.id)) {
      debugPrint('Circular move detected: Cannot move ${dragged.id} into its own descendant ${target.id}');
      return;
    }

    // First, detach from current parent
    removeNode(dragged);

    // Re-find target in case node removal (if target was a descendant of a sibling)
    // though removeNode only removes the dragged node and its descendants.
    final actualTarget = findNodeById(target.id);
    if (actualTarget == null) return;

    if (nestInside) {
      final targetData = actualTarget.data;
      if (targetData is SuperTreeData && !targetData.canHaveChildren) {
        assert(false, 'Cannot nest inside a node that returns canHaveChildren = false');
        return;
      }
      addChild(actualTarget, dragged);
      expandNode(actualTarget); // Auto expand to show the dropped child
    } else {
      final parent = actualTarget.parent;
      int index = 0;

      if (parent != null) {
        if (_sortComparator != null) {
          parent.internalAddChild(dragged);
          parent.internalSortChildren(_sortComparator!);
        } else {
          index = parent.children.indexOf(actualTarget);
          if (!insertBefore) index++;
          parent.internalInsertChild(index, dragged);
        }
      } else {
        if (_sortComparator != null) {
          _roots.add(dragged);
          _roots.sort(_sortComparator!);
        } else {
          index = _roots.indexOf(actualTarget);
          if (!insertBefore) index++;
          _roots.insert(index, dragged);
        }
      }
    }
    _rebuildFlatList();
    notifyListeners();
  }

  /// Returns true if the node with [childId] is a descendant of the node with [parentId].
  bool isDescendantOf(String childId, String parentId) {
    final TreeNode<T>? child = findNodeById(childId);
    if (child == null) return false;
    
    TreeNode<T>? cursor = child.parent;
    while (cursor != null) {
      if (cursor.id == parentId) return true;
      cursor = cursor.parent;
    }
    return false;
  }

  /// Finds a node by its ID. Returns null if not found.
  TreeNode<T>? findNodeById(String id) {
    return _nodeIndex[id];
  }
}
