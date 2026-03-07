import 'package:flutter/foundation.dart';
import 'package:super_tree/src/models/super_tree_data.dart';
import 'package:super_tree/src/models/tree_filtering.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Callback used to lazily resolve children for a node.
typedef TreeLoadChildrenCallback<T> = Future<List<TreeNode<T>>> Function(TreeNode<T> node);

/// Read-only async UI state for a node.
class TreeNodeAsyncState {
  const TreeNodeAsyncState({
    required this.isLoading,
    required this.error,
  });

  final bool isLoading;
  final Object? error;

  bool get hasError => error != null;
}

class _FilterTraversalResult<T> {
  const _FilterTraversalResult({
    required this.visibleNodes,
    required this.hasMatch,
  });

  final List<TreeNode<T>> visibleNodes;
  final bool hasMatch;
}

/// Manages the state and structure of the tree.
/// 
/// The [TreeController] is independent of the UI and provides methods to
/// expand, collapse, add, remove, and traverse nodes. It calculates and caches
/// a flat list of visible nodes [flatVisibleNodes] to be efficiently consumed
/// by a `ListView.builder` in the UI layer.
class TreeController<T> extends ChangeNotifier {
  final List<TreeNode<T>> _roots;

  final TreeLoadChildrenCallback<T>? _loadChildren;
  
  /// Optional comparator to keep the tree sorted.
  int Function(TreeNode<T> a, TreeNode<T> b)? _sortComparator;

  /// Cache of the flat visible nodes computed from the current tree state.
  final List<TreeNode<T>> _flatVisibleNodes = [];

  /// Match metadata for the currently active query by node ID.
  final Map<String, List<int>> _matchedIndicesByNodeId = <String, List<int>>{};

  /// Active filtering predicate.
  TreeNodeFilter<T>? _activeFilter;

  /// Index for O(1) node lookup by ID.
  final Map<String, TreeNode<T>> _nodeIndex = {};

  /// Node IDs that have completed lazy loading at least once.
  final Set<String> _lazyLoadedNodeIds = <String>{};

  /// Node IDs that currently have a pending lazy-loading request.
  final Set<String> _loadingNodeIds = <String>{};

  /// Last loading error by node ID.
  final Map<String, Object> _loadErrorsByNodeId = <String, Object>{};

  /// Creates a new [TreeController] initialized with optional [roots].
  /// 
  /// [sortComparator] can be used to keep the tree automatically sorted.
  /// [onNodeRenamed] and [onNodeDeleted] are useful for listening to state changes
  /// triggered by high-level actions.
  TreeController({
    List<TreeNode<T>>? roots,
    int Function(TreeNode<T> a, TreeNode<T> b)? sortComparator,
    TreeLoadChildrenCallback<T>? loadChildren,
    this.onNodeRenamed,
    this.onNodeDeleted,
  }) : _roots = roots ?? <TreeNode<T>>[],
       _sortComparator = sortComparator,
       _loadChildren = loadChildren {
    for (var root in _roots) {
      _indexNode(root);
      _markInitialLoadedState(root);
    }
    _rebuildFlatList();
  }

  void _markInitialLoadedState(TreeNode<T> node) {
    if (node.hasChildren || !node.canLoadChildren) {
      _lazyLoadedNodeIds.add(node.id);
    }
    for (final TreeNode<T> child in node.children) {
      _markInitialLoadedState(child);
    }
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

  /// Whether a filter is currently active.
  bool get hasActiveFilter => _activeFilter != null;

  /// Returns highlighted character indices for [nodeId] under the active query.
  List<int> getMatchedIndices(String nodeId) {
    final List<int>? value = _matchedIndicesByNodeId[nodeId];
    if (value == null) {
      return const <int>[];
    }
    return List<int>.unmodifiable(value);
  }

  /// Returns true when [nodeId] has matched query indices for highlighting.
  bool hasMatchedIndices(String nodeId) {
    return _matchedIndicesByNodeId.containsKey(nodeId);
  }

  /// Re-calculates the flat visible lists using Depth First Traversal.
  void _rebuildFlatList() {
    _flatVisibleNodes.clear();

    if (!hasActiveFilter) {
      _matchedIndicesByNodeId.clear();
      for (var root in _roots) {
        _flattenNode(root);
      }
      return;
    }

    for (var root in _roots) {
      final _FilterTraversalResult<T> result = _collectFiltered(root, ancestorMatched: false);
      _flatVisibleNodes.addAll(result.visibleNodes);
    }
  }

  _FilterTraversalResult<T> _collectFiltered(TreeNode<T> node, {required bool ancestorMatched}) {
    final bool selfMatches = _nodeMatchesFilter(node);
    final bool nextAncestorMatched = ancestorMatched || selfMatches;

    bool descendantMatches = false;
    final List<TreeNode<T>> visibleChildren = <TreeNode<T>>[];

    for (var child in node.children) {
      final _FilterTraversalResult<T> childResult = _collectFiltered(
        child,
        ancestorMatched: nextAncestorMatched,
      );
      descendantMatches = descendantMatches || childResult.hasMatch;
      visibleChildren.addAll(childResult.visibleNodes);
    }

    final bool includeNode = ancestorMatched || selfMatches || descendantMatches;
    if (!includeNode) {
      return _FilterTraversalResult<T>(
        visibleNodes: <TreeNode<T>>[],
        hasMatch: selfMatches || descendantMatches,
      );
    }

    return _FilterTraversalResult<T>(
      visibleNodes: <TreeNode<T>>[node, ...visibleChildren],
      hasMatch: selfMatches || descendantMatches,
    );
  }

  bool _nodeMatchesFilter(TreeNode<T> node) {
    if (_activeFilter == null) {
      return true;
    }
    return _activeFilter!.call(node);
  }

  /// Applies a visibility filter predicate.
  ///
  /// Optional [matchedIndicesByNodeId] is used by UI layers that render
  /// highlighted text for search matches.
  void applyFilter({
    required TreeNodeFilter<T> predicate,
    Map<String, List<int>>? matchedIndicesByNodeId,
  }) {
    _activeFilter = predicate;
    _setMatchedIndices(matchedIndicesByNodeId);
    _rebuildFlatList();
    notifyListeners();
  }

  void _setMatchedIndices(Map<String, List<int>>? matchedIndicesByNodeId) {
    _matchedIndicesByNodeId
      ..clear()
      ..addAll(
        matchedIndicesByNodeId == null
            ? const <String, List<int>>{}
            : matchedIndicesByNodeId.map(
                (String key, List<int> value) => MapEntry<String, List<int>>(key, List<int>.from(value)),
              ),
      );
  }

  /// Clears the active filter and restores default visibility behavior.
  void clearFilter() {
    if (!hasActiveFilter && _matchedIndicesByNodeId.isEmpty) {
      return;
    }

    _activeFilter = null;
    _matchedIndicesByNodeId.clear();
    _rebuildFlatList();
    notifyListeners();
  }

  /// Rebuilds the visible list and notifies listeners after external data mutation.
  ///
  /// This is useful when consumers mutate node data in-place and need a single
  /// explicit refresh point without triggering unrelated selection changes.
  void refresh() {
    _rebuildFlatList();
    notifyListeners();
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

  /// Clears lazy-loading state for a node subtree.
  void _clearLazyStateForSubtree(TreeNode<T> node) {
    _loadingNodeIds.remove(node.id);
    _lazyLoadedNodeIds.remove(node.id);
    _loadErrorsByNodeId.remove(node.id);
    for (final TreeNode<T> child in node.children) {
      _clearLazyStateForSubtree(child);
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

  /// Returns `true` if [nodeId] is currently loading children.
  bool isNodeLoading(String nodeId) => _loadingNodeIds.contains(nodeId);

  /// Returns the last lazy-loading error for [nodeId], if any.
  Object? getNodeLoadError(String nodeId) => _loadErrorsByNodeId[nodeId];

  /// Returns `true` if [nodeId] has a captured lazy-loading error.
  bool hasNodeLoadError(String nodeId) => _loadErrorsByNodeId.containsKey(nodeId);

  /// Returns whether a node can trigger lazy loading.
  bool canNodeLoadChildren(TreeNode<T> node) {
    return _loadChildren != null &&
        node.canLoadChildren &&
        !node.hasChildren &&
        !_lazyLoadedNodeIds.contains(node.id);
  }

  /// Gets an immutable async state snapshot for [nodeId].
  TreeNodeAsyncState getNodeAsyncState(String nodeId) {
    return TreeNodeAsyncState(
      isLoading: isNodeLoading(nodeId),
      error: getNodeLoadError(nodeId),
    );
  }

  /// Clears the lazy-loading error for [nodeId].
  void clearNodeLoadError(String nodeId) {
    final bool removed = _loadErrorsByNodeId.remove(nodeId) != null;
    if (removed) {
      notifyListeners();
    }
  }

  /// Ensures lazy children are loaded for [node] if needed.
  ///
  /// No-op when no lazy loader is configured or the node is already loaded.
  Future<void> ensureNodeChildrenLoaded(TreeNode<T> node) async {
    if (!canNodeLoadChildren(node)) {
      return;
    }

    final String nodeId = node.id;
    if (_loadingNodeIds.contains(nodeId)) {
      return;
    }

    _loadingNodeIds.add(nodeId);
    _loadErrorsByNodeId.remove(nodeId);
    notifyListeners();

    try {
      final TreeLoadChildrenCallback<T>? loadChildren = _loadChildren;
      if (loadChildren == null) {
        return;
      }

      final List<TreeNode<T>> children = await loadChildren(node);
      if (findNodeById(nodeId) == null) {
        return;
      }

      for (final TreeNode<T> child in children) {
        _indexNode(child);
        node.internalAddChild(child);
      }

      if (_sortComparator != null) {
        node.internalSortChildren(_sortComparator!);
      }

      node.canLoadChildren = false;
      _lazyLoadedNodeIds.add(nodeId);
      _loadErrorsByNodeId.remove(nodeId);
      if (node.isExpanded) {
        _rebuildFlatList();
      }
    } catch (error) {
      _loadErrorsByNodeId[nodeId] = error;
    } finally {
      _loadingNodeIds.remove(nodeId);
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
  Future<void> toggleNodeExpansion(TreeNode<T> node) async {
    if (node.isExpanded) {
      collapseNode(node);
    } else {
      await ensureNodeChildrenLoaded(node);
      if (isNodeLoading(node.id) || hasNodeLoadError(node.id)) {
        return;
      }
      if (!node.hasChildren) {
        return;
      }
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

  /// The ID of the node that serves as the anchor for range selection (Shift + Click).
  String? _anchorNodeId;

  /// Gets the first selected node ID, if any.
  String? get selectedNodeId => _selectedNodeIds.isEmpty ? null : (_anchorNodeId ?? _selectedNodeIds.first);

  /// Deselects all nodes.
  void deselectAll() {
    if (_selectedNodeIds.isNotEmpty) {
      _selectedNodeIds.clear();
      _anchorNodeId = null;
      notifyListeners();
    }
  }

  /// Update the current selected node ID (single selection).
  void setSelectedNodeId(String? id) {
    _selectedNodeIds.clear();
    _anchorNodeId = id;
    if (id != null) {
      _selectedNodeIds.add(id);
    }
    notifyListeners();
  }

  /// Toggles selection of a node.
  void toggleSelection(String id) {
    if (_selectedNodeIds.contains(id)) {
      _selectedNodeIds.remove(id);
      if (_anchorNodeId == id) {
        _anchorNodeId = _selectedNodeIds.isNotEmpty ? _selectedNodeIds.last : null;
      }
    } else {
      _selectedNodeIds.add(id);
      _anchorNodeId = id;
    }
    notifyListeners();
  }

  /// Selects a range of nodes from the anchor node to the target node.
  void selectRange(String targetId) {
    if (_flatVisibleNodes.isEmpty) return;
    
    final anchorId = _anchorNodeId ?? (_selectedNodeIds.isNotEmpty ? _selectedNodeIds.last : _flatVisibleNodes.first.id);
    final startIndex = _flatVisibleNodes.indexWhere((n) => n.id == anchorId);
    final endIndex = _flatVisibleNodes.indexWhere((n) => n.id == targetId);
    
    if (startIndex == -1 || endIndex == -1) return;
    
    final min = startIndex < endIndex ? startIndex : endIndex;
    final max = startIndex < endIndex ? endIndex : startIndex;
    
    _selectedNodeIds.clear();
    for (int i = min; i <= max; i++) {
      _selectedNodeIds.add(_flatVisibleNodes[i].id);
    }
    // We don't update anchorId here because we want to keep the original anchor for expanding ranges
    _anchorNodeId = anchorId; 

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

  /// Serializes controller UI state for persistence.
  ///
  /// The payload intentionally stores interaction state only and does not
  /// include node business data.
  Map<String, Object?> toJson() {
    final List<String> expandedNodeIds = _nodeIndex.values
        .where((TreeNode<T> node) => node.isExpanded)
        .map((TreeNode<T> node) => node.id)
        .toList()
      ..sort();

    return <String, Object?>{
      'version': 1,
      'expandedNodeIds': expandedNodeIds,
      'selectedNodeIds': _selectedNodeIds.toList(),
      'anchorNodeId': _anchorNodeId,
    };
  }

  /// Restores controller UI state from a payload generated by [toJson].
  ///
  /// Unknown IDs, missing keys, and malformed values are ignored gracefully.
  void fromJson(Map<String, Object?> json) {
    final Set<String> expandedNodeIds = _readStringList(
      json['expandedNodeIds'],
    ).toSet();
    final List<String> selectedNodeIds = _readStringList(json['selectedNodeIds']);
    final Object? rawAnchorValue = json['anchorNodeId'];
    final String? rawAnchorNodeId =
      rawAnchorValue is String ? rawAnchorValue : null;

    for (final TreeNode<T> node in _nodeIndex.values) {
      node.isExpanded = expandedNodeIds.contains(node.id);
    }

    _selectedNodeIds.clear();
    for (final String nodeId in selectedNodeIds) {
      if (_nodeIndex.containsKey(nodeId)) {
        _selectedNodeIds.add(nodeId);
      }
    }

    if (rawAnchorNodeId != null && _selectedNodeIds.contains(rawAnchorNodeId)) {
      _anchorNodeId = rawAnchorNodeId;
    } else {
      _anchorNodeId = _selectedNodeIds.isNotEmpty ? _selectedNodeIds.last : null;
    }

    _rebuildFlatList();
    notifyListeners();
  }

  List<String> _readStringList(Object? value) {
    if (value is! List<Object?>) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .where((String item) => item.isNotEmpty)
        .toList();
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

  /// Creates a temporary "new" node as a child of [parent].
  /// The node will be in renaming mode immediately.
  void createNewChild(TreeNode<T> parent, T initialData) {
    final newNode = TreeNode<T>(data: initialData, isNew: true);
    addChild(parent, newNode);
    expandNode(parent);
    setRenamingNodeId(newNode.id);
  }

  /// Creates a temporary "new" node as a root.
  /// The node will be in renaming mode immediately.
  void createNewRoot(T initialData) {
    final newNode = TreeNode<T>(data: initialData, isNew: true);
    addRoot(newNode);
    setRenamingNodeId(newNode.id);
  }

  /// Submits a rename action for a specific node.
  /// If the node was new, it resets the [isNew] flag after renaming.
  void renameNode(String id, String newName) {
    final node = findNodeById(id);
    if (node != null) {
      final wasNew = node.isNew;
      node.isNew = false;
      onNodeRenamed?.call(node, newName);
      setRenamingNodeId(null);
      
      // If it was new, we might need to re-sort as the name changed
      if (wasNew && _sortComparator != null) {
        if (node.isRoot) {
          _roots.sort(_sortComparator!);
        } else {
          node.parent?.internalSortChildren(_sortComparator!);
        }
        _rebuildFlatList();
        notifyListeners();
      }
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
    _clearLazyStateForSubtree(node);
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

    // 1. Validation
    // Preventive check: Cannot drop a node into its own descendant
    if (isDescendantOf(target.id, dragged.id)) {
      debugPrint('Circular move detected: Cannot move ${dragged.id} into its own descendant ${target.id}');
      return;
    }

    // If nesting, check if target can have children
    if (nestInside) {
      final targetData = target.data;
      if (targetData is SuperTreeData && !targetData.canHaveChildren) {
        debugPrint('Cannot move into node that cannot have children: ${target.id}');
        return;
      }
    }

    // 2. Atomic mutation
    // Detach from current parent
    final oldParent = dragged.parent;
    if (oldParent != null) {
      oldParent.internalRemoveChild(dragged);
    } else {
      _roots.remove(dragged);
    }

    // Re-find target in index just to be absolutely sure it hasn't somehow disappeared
    final actualTarget = findNodeById(target.id);
    if (actualTarget == null) {
      // If target disappeared, we just leave the dragged node detached? 
      // safer to re-attach to old parent?
      if (oldParent != null) {
        oldParent.internalAddChild(dragged);
      } else {
        _roots.add(dragged);
      }
      return;
    }

    // Re-attach to new location
    if (nestInside) {
      actualTarget.internalAddChild(dragged);
      actualTarget.isExpanded = true; 
    } else {
      final parent = actualTarget.parent;
      if (parent != null) {
        int index = parent.children.indexOf(actualTarget);
        if (!insertBefore) index++;
        parent.internalInsertChild(index, dragged);
      } else {
        int index = _roots.indexOf(actualTarget);
        if (!insertBefore) index++;
        _roots.insert(index, dragged);
      }
    }

    // 3. Finalize
    if (_sortComparator != null) {
      _sortTree();
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
