import 'package:flutter/foundation.dart';
import 'package:super_tree/src/models/super_tree_data.dart';
import 'package:super_tree/src/models/tree_filtering.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Callback used to lazily resolve children for a node.
typedef TreeLoadChildrenCallback<T> =
    Future<List<TreeNode<T>>> Function(TreeNode<T> node);

/// Read-only async UI state for a node.
class TreeNodeAsyncState {
  const TreeNodeAsyncState({
    required this.state,
    required this.isLoading,
    required this.error,
  });

  final TreeNodeState state;

  final bool isLoading;
  final Object? error;

  bool get hasError => error != null;
}

/// Integrity issue types emitted when operations are rejected to keep the graph valid.
enum TreeIntegrityIssueType { duplicateId, circularReference }

/// Describes a non-fatal graph integrity issue.
class TreeIntegrityIssue {
  const TreeIntegrityIssue({
    required this.type,
    required this.message,
    required this.operation,
    this.nodeId,
    this.relatedNodeId,
  });

  final TreeIntegrityIssueType type;
  final String message;
  final String operation;
  final String? nodeId;
  final String? relatedNodeId;
}

class _FilterTraversalResult<T> {
  const _FilterTraversalResult({
    required this.visibleNodes,
    required this.hasMatch,
  });

  final List<TreeNode<T>> visibleNodes;
  final bool hasMatch;
}

class _NodeLocation<T> {
  const _NodeLocation({required this.parent, required this.index});

  final TreeNode<T>? parent;
  final int index;
}

class _DetachedNode<T> {
  const _DetachedNode({required this.node, required this.index});

  final TreeNode<T> node;
  final int index;
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

  /// Last integrity issue emitted by validation guards.
  TreeIntegrityIssue? _lastIntegrityIssue;

  /// Integrity issues keyed by node ID for UI-level surfacing.
  final Map<String, TreeIntegrityIssue> _integrityIssuesByNodeId =
      <String, TreeIntegrityIssue>{};

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
  }) : _roots = <TreeNode<T>>[],
       _sortComparator = sortComparator,
       _loadChildren = loadChildren {
    final List<TreeNode<T>> initialRoots = roots ?? <TreeNode<T>>[];
    for (final TreeNode<T> root in initialRoots) {
      if (!_canIndexNodes(
        <TreeNode<T>>[root],
        operation: 'initialize',
        notify: false,
      )) {
        continue;
      }

      _indexSubtree(root);
      _roots.add(root);
      _markInitialLoadedState(root);
    }
    _rebuildFlatList();
  }

  void _markInitialLoadedState(TreeNode<T> node) {
    if (node.hasChildren || !node.canLoadChildren) {
      node.nodeState = TreeNodeState.loaded;
      node.loadError = null;
    } else if (node.nodeState != TreeNodeState.loading) {
      node.nodeState = TreeNodeState.idle;
      node.loadError = null;
    }

    for (final TreeNode<T> child in node.children) {
      _markInitialLoadedState(child);
    }
  }

  /// Callback generated when a node is renamed.
  final void Function(TreeNode<T> node, String newName)? onNodeRenamed;

  /// Callback generated when a node is deleted.
  final void Function(TreeNode<T> node)? onNodeDeleted;

  /// Last integrity issue emitted by graph guards.
  TreeIntegrityIssue? get lastIntegrityIssue => _lastIntegrityIssue;

  /// Per-node integrity issues that can be rendered in row UIs.
  Map<String, TreeIntegrityIssue> get integrityIssuesByNodeId =>
      Map<String, TreeIntegrityIssue>.unmodifiable(_integrityIssuesByNodeId);

  /// Returns the integrity issue associated with [nodeId], if any.
  TreeIntegrityIssue? getIntegrityIssueForNode(String nodeId) {
    return _integrityIssuesByNodeId[nodeId];
  }

  /// Clears all recorded integrity issues.
  void clearIntegrityIssues() {
    if (_lastIntegrityIssue == null && _integrityIssuesByNodeId.isEmpty) {
      return;
    }

    _lastIntegrityIssue = null;
    _integrityIssuesByNodeId.clear();
    notifyListeners();
  }

  /// Gets the current sort comparator.
  int Function(TreeNode<T> a, TreeNode<T> b)? get sortComparator =>
      _sortComparator;

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
  List<TreeNode<T>> get flatVisibleNodes =>
      List.unmodifiable(_flatVisibleNodes);

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
      final _FilterTraversalResult<T> result = _collectFiltered(
        root,
        ancestorMatched: false,
      );
      _flatVisibleNodes.addAll(result.visibleNodes);
    }
  }

  _FilterTraversalResult<T> _collectFiltered(
    TreeNode<T> node, {
    required bool ancestorMatched,
  }) {
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

    final bool includeNode =
        ancestorMatched || selfMatches || descendantMatches;
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
                (String key, List<int> value) =>
                    MapEntry<String, List<int>>(key, List<int>.from(value)),
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

  void _reportIntegrityIssue(TreeIntegrityIssue issue, {bool notify = true}) {
    _lastIntegrityIssue = issue;

    if (issue.nodeId != null) {
      _integrityIssuesByNodeId[issue.nodeId!] = issue;
    }
    if (issue.relatedNodeId != null) {
      _integrityIssuesByNodeId[issue.relatedNodeId!] = issue;
    }

    debugPrint(
      '[SuperTree] Integrity issue (${issue.type.name}) during ${issue.operation}: ${issue.message}',
    );

    if (notify) {
      notifyListeners();
    }
  }

  bool _canIndexNodes(
    List<TreeNode<T>> nodes, {
    required String operation,
    String? targetNodeId,
    bool notify = true,
  }) {
    final Set<String> seenIds = <String>{..._nodeIndex.keys};
    String? duplicateId;

    bool visit(TreeNode<T> node) {
      if (seenIds.contains(node.id)) {
        duplicateId = node.id;
        return false;
      }

      seenIds.add(node.id);
      for (final TreeNode<T> child in node.children) {
        if (!visit(child)) {
          return false;
        }
      }

      return true;
    }

    for (final TreeNode<T> root in nodes) {
      if (!visit(root)) {
        break;
      }
    }

    if (duplicateId == null) {
      return true;
    }

    final String message =
        'Duplicate node ID detected: "$duplicateId". Operation was ignored to preserve graph integrity.';
    _reportIntegrityIssue(
      TreeIntegrityIssue(
        type: TreeIntegrityIssueType.duplicateId,
        message: message,
        operation: operation,
        nodeId: targetNodeId,
        relatedNodeId: duplicateId,
      ),
      notify: notify,
    );
    return false;
  }

  /// Indexes a node and all its descendants recursively.
  void _indexSubtree(TreeNode<T> node) {
    _nodeIndex[node.id] = node;
    for (final TreeNode<T> child in node.children) {
      _indexSubtree(child);
    }
  }

  /// Unindexes a node and all its descendants recursively.
  void _unindexNode(TreeNode<T> node) {
    _nodeIndex.remove(node.id);
    for (final TreeNode<T> child in node.children) {
      _unindexNode(child);
    }
  }

  void _clearIntegrityIssuesForSubtree(TreeNode<T> node) {
    _integrityIssuesByNodeId.remove(node.id);
    for (final TreeNode<T> child in node.children) {
      _clearIntegrityIssuesForSubtree(child);
    }
  }

  /// Clears lazy-loading state for a node subtree.
  void _clearLazyStateForSubtree(TreeNode<T> node) {
    node.nodeState = node.canLoadChildren
        ? TreeNodeState.idle
        : TreeNodeState.loaded;
    node.loadError = null;
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
  bool isNodeLoading(String nodeId) {
    final TreeNode<T>? node = findNodeById(nodeId);
    return node?.nodeState == TreeNodeState.loading;
  }

  /// Returns the last lazy-loading error for [nodeId], if any.
  Object? getNodeLoadError(String nodeId) {
    final TreeNode<T>? node = findNodeById(nodeId);
    return node?.loadError;
  }

  /// Returns `true` if [nodeId] has a captured lazy-loading error.
  bool hasNodeLoadError(String nodeId) {
    final TreeNode<T>? node = findNodeById(nodeId);
    return node?.nodeState == TreeNodeState.error;
  }

  /// Returns enum-based lazy-loading state for [nodeId].
  TreeNodeState getNodeState(String nodeId) {
    final TreeNode<T>? node = findNodeById(nodeId);
    return node?.nodeState ?? TreeNodeState.loaded;
  }

  /// Returns whether a node can trigger lazy loading.
  bool canNodeLoadChildren(TreeNode<T> node) {
    return _loadChildren != null &&
        node.canLoadChildren &&
        !node.hasChildren &&
        node.nodeState != TreeNodeState.loaded;
  }

  /// Gets an immutable async state snapshot for [nodeId].
  TreeNodeAsyncState getNodeAsyncState(String nodeId) {
    final TreeNode<T>? node = findNodeById(nodeId);
    if (node == null) {
      return const TreeNodeAsyncState(
        state: TreeNodeState.loaded,
        isLoading: false,
        error: null,
      );
    }

    return TreeNodeAsyncState(
      state: node.nodeState,
      isLoading: node.nodeState == TreeNodeState.loading,
      error: node.loadError,
    );
  }

  /// Clears the lazy-loading error for [nodeId].
  void clearNodeLoadError(String nodeId) {
    final TreeNode<T>? node = findNodeById(nodeId);
    if (node == null || node.loadError == null) {
      return;
    }

    node.loadError = null;
    if (node.nodeState == TreeNodeState.error) {
      node.nodeState = node.canLoadChildren
          ? TreeNodeState.idle
          : TreeNodeState.loaded;
    }
    notifyListeners();
  }

  /// Ensures lazy children are loaded for [node] if needed.
  ///
  /// No-op when no lazy loader is configured or the node is already loaded.
  Future<void> ensureNodeChildrenLoaded(TreeNode<T> node) async {
    if (!canNodeLoadChildren(node)) {
      return;
    }

    final String nodeId = node.id;
    if (node.nodeState == TreeNodeState.loading) {
      return;
    }

    node.nodeState = TreeNodeState.loading;
    node.loadError = null;
    notifyListeners();

    try {
      final TreeLoadChildrenCallback<T>? loadChildren = _loadChildren;
      if (loadChildren == null) {
        return;
      }

      final List<TreeNode<T>> children = await loadChildren(node);
      final TreeNode<T>? refreshedNode = findNodeById(nodeId);
      if (refreshedNode == null) {
        return;
      }

      if (!_canIndexNodes(
        children,
        operation: 'ensureNodeChildrenLoaded',
        targetNodeId: nodeId,
        notify: false,
      )) {
        refreshedNode.nodeState = TreeNodeState.error;
        refreshedNode.loadError = StateError(
          'Duplicate node IDs were returned while loading children for "$nodeId".',
        );
        return;
      }

      for (final TreeNode<T> child in children) {
        _indexSubtree(child);
        refreshedNode.internalAddChild(child);
      }

      if (_sortComparator != null) {
        refreshedNode.internalSortChildren(_sortComparator!);
      }

      refreshedNode.canLoadChildren = false;
      refreshedNode.nodeState = TreeNodeState.loaded;
      refreshedNode.loadError = null;
      if (refreshedNode.isExpanded) {
        _rebuildFlatList();
      }
    } catch (error) {
      final TreeNode<T>? refreshedNode = findNodeById(nodeId);
      if (refreshedNode != null) {
        refreshedNode.nodeState = TreeNodeState.error;
        refreshedNode.loadError = error;
      }
    } finally {
      final TreeNode<T>? refreshedNode = findNodeById(nodeId);
      if (refreshedNode != null &&
          refreshedNode.nodeState == TreeNodeState.loading) {
        refreshedNode.nodeState = refreshedNode.canLoadChildren
            ? TreeNodeState.idle
            : TreeNodeState.loaded;
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
        _flatVisibleNodes.removeRange(
          index + 1,
          index + 1 + descendants.length,
        );
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
  String? get selectedNodeId => _selectedNodeIds.isEmpty
      ? null
      : (_anchorNodeId ?? _selectedNodeIds.first);

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
        _anchorNodeId = _selectedNodeIds.isNotEmpty
            ? _selectedNodeIds.last
            : null;
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

    final anchorId =
        _anchorNodeId ??
        (_selectedNodeIds.isNotEmpty
            ? _selectedNodeIds.last
            : _flatVisibleNodes.first.id);
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

    final currentIndex = _flatVisibleNodes.indexWhere(
      (n) => n.id == lastSelected,
    );
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

    final currentIndex = _flatVisibleNodes.indexWhere(
      (n) => n.id == lastSelected,
    );
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

  /// Returns selected nodes in current visible order.
  ///
  /// When [topLevelOnly] is true, descendants of already selected parents are
  /// omitted so drag/drop can move selection groups without duplicates.
  List<TreeNode<T>> getSelectedNodesInVisibleOrder({bool topLevelOnly = false}) {
    if (_selectedNodeIds.isEmpty) {
      return <TreeNode<T>>[];
    }

    final List<TreeNode<T>> selected = _flatVisibleNodes
        .where((TreeNode<T> node) => _selectedNodeIds.contains(node.id))
        .toList(growable: false);
    if (!topLevelOnly) {
      return selected;
    }

    final Set<String> selectedIds = Set<String>.from(_selectedNodeIds);
    return selected
        .where((TreeNode<T> node) => !_hasSelectedAncestor(node, selectedIds))
        .toList(growable: false);
  }

  bool _hasSelectedAncestor(TreeNode<T> node, Set<String> selectedIds) {
    TreeNode<T>? cursor = node.parent;
    while (cursor != null) {
      if (selectedIds.contains(cursor.id)) {
        return true;
      }
      cursor = cursor.parent;
    }
    return false;
  }

  /// Serializes controller UI state for persistence.
  ///
  /// The payload intentionally stores interaction state only and does not
  /// include node business data.
  Map<String, Object?> toJson() {
    final List<String> expandedNodeIds =
        _nodeIndex.values
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
    final List<String> selectedNodeIds = _readStringList(
      json['selectedNodeIds'],
    );
    final Object? rawAnchorValue = json['anchorNodeId'];
    final String? rawAnchorNodeId = rawAnchorValue is String
        ? rawAnchorValue
        : null;

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
      _anchorNodeId = _selectedNodeIds.isNotEmpty
          ? _selectedNodeIds.last
          : null;
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
    if (!_canIndexNodes(<TreeNode<T>>[node], operation: 'addRoot')) {
      return;
    }

    _indexSubtree(node);
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
      assert(
        false,
        'Cannot add a child to a node that returns canHaveChildren = false',
      );
      return;
    }

    final bool createsCycle =
        parent.id == child.id || isDescendantOf(parent.id, child.id);
    if (createsCycle) {
      final String message =
          'Cannot add "${child.id}" as child of "${parent.id}": operation would create a circular reference.';
      _reportIntegrityIssue(
        TreeIntegrityIssue(
          type: TreeIntegrityIssueType.circularReference,
          message: message,
          operation: 'addChild',
          nodeId: parent.id,
          relatedNodeId: child.id,
        ),
      );
      return;
    }

    if (!_canIndexNodes(
      <TreeNode<T>>[child],
      operation: 'addChild',
      targetNodeId: parent.id,
    )) {
      return;
    }

    _indexSubtree(child);
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
    _clearIntegrityIssuesForSubtree(node);
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
    moveNodes(
      draggedNodes: <TreeNode<T>>[dragged],
      target: target,
      insertBefore: insertBefore,
      nestInside: nestInside,
    );
  }

  /// Moves multiple nodes atomically relative to a target node.
  ///
  /// Returns true when the move succeeds. If any dragged node is invalid for
  /// the requested destination, no mutation is applied.
  bool moveNodes({
    required List<TreeNode<T>> draggedNodes,
    required TreeNode<T> target,
    required bool insertBefore,
    bool nestInside = false,
  }) {
    if (draggedNodes.isEmpty) {
      return false;
    }

    final List<TreeNode<T>> uniqueDragged = <TreeNode<T>>[];
    final Set<String> seenIds = <String>{};
    for (final TreeNode<T> node in draggedNodes) {
      if (seenIds.add(node.id)) {
        uniqueDragged.add(node);
      }
    }

    if (uniqueDragged.isEmpty) {
      return false;
    }

    final Set<String> draggedIds = uniqueDragged
        .map((TreeNode<T> node) => node.id)
        .toSet();
    if (draggedIds.contains(target.id)) {
      final TreeNode<T> firstNode = uniqueDragged.first;
      final String message =
          'Cannot move "${firstNode.id}" onto itself or within the same dragged selection.';
      _reportIntegrityIssue(
        TreeIntegrityIssue(
          type: TreeIntegrityIssueType.circularReference,
          message: message,
          operation: 'moveNodes',
          nodeId: firstNode.id,
          relatedNodeId: target.id,
        ),
      );
      return false;
    }

    for (final TreeNode<T> draggedNode in uniqueDragged) {
      if (isDescendantOf(target.id, draggedNode.id)) {
        final String message =
            'Cannot move "${draggedNode.id}" into its own descendant "${target.id}".';
        _reportIntegrityIssue(
          TreeIntegrityIssue(
            type: TreeIntegrityIssueType.circularReference,
            message: message,
            operation: 'moveNodes',
            nodeId: draggedNode.id,
            relatedNodeId: target.id,
          ),
        );
        return false;
      }
    }

    if (nestInside) {
      final Object? targetData = target.data;
      if (targetData is SuperTreeData && !targetData.canHaveChildren) {
        debugPrint(
          'Cannot move into node that cannot have children: ${target.id}',
        );
        return false;
      }
    }

    final Map<String, _NodeLocation<T>> originalLocations =
        <String, _NodeLocation<T>>{};
    for (final TreeNode<T> draggedNode in uniqueDragged) {
      final _NodeLocation<T>? location = _captureNodeLocation(draggedNode);
      if (location == null) {
        return false;
      }
      originalLocations[draggedNode.id] = location;
    }

    for (final TreeNode<T> draggedNode in uniqueDragged) {
      final TreeNode<T>? oldParent = draggedNode.parent;
      if (oldParent != null) {
        oldParent.internalRemoveChild(draggedNode);
      } else {
        _roots.remove(draggedNode);
      }
    }

    final TreeNode<T>? actualTarget = findNodeById(target.id);
    if (actualTarget == null) {
      _restoreDetachedNodes(
        originalLocations: originalLocations,
        orderedNodes: uniqueDragged,
      );
      return false;
    }

    if (nestInside) {
      for (final TreeNode<T> draggedNode in uniqueDragged) {
        actualTarget.internalAddChild(draggedNode);
      }
      actualTarget.isExpanded = true;
    } else {
      final TreeNode<T>? parent = actualTarget.parent;
      if (parent != null) {
        int insertionIndex = parent.children.indexOf(actualTarget);
        if (insertionIndex < 0) {
          _restoreDetachedNodes(
            originalLocations: originalLocations,
            orderedNodes: uniqueDragged,
          );
          return false;
        }
        if (!insertBefore) {
          insertionIndex++;
        }

        for (final TreeNode<T> draggedNode in uniqueDragged) {
          parent.internalInsertChild(insertionIndex, draggedNode);
          insertionIndex++;
        }
      } else {
        int insertionIndex = _roots.indexOf(actualTarget);
        if (insertionIndex < 0) {
          _restoreDetachedNodes(
            originalLocations: originalLocations,
            orderedNodes: uniqueDragged,
          );
          return false;
        }
        if (!insertBefore) {
          insertionIndex++;
        }

        for (final TreeNode<T> draggedNode in uniqueDragged) {
          draggedNode.parent = null;
          _roots.insert(insertionIndex, draggedNode);
          insertionIndex++;
        }
      }
    }

    if (_sortComparator != null) {
      _sortTree();
    }
    _rebuildFlatList();
    notifyListeners();
    return true;
  }

  _NodeLocation<T>? _captureNodeLocation(TreeNode<T> node) {
    final TreeNode<T>? parent = node.parent;
    final int index = parent != null
        ? parent.children.indexOf(node)
        : _roots.indexOf(node);
    if (index < 0) {
      return null;
    }

    return _NodeLocation<T>(parent: parent, index: index);
  }

  void _restoreDetachedNodes({
    required Map<String, _NodeLocation<T>> originalLocations,
    required List<TreeNode<T>> orderedNodes,
  }) {
    final Map<TreeNode<T>?, List<_DetachedNode<T>>> grouped =
        <TreeNode<T>?, List<_DetachedNode<T>>>{};
    for (final TreeNode<T> node in orderedNodes) {
      final _NodeLocation<T>? location = originalLocations[node.id];
      if (location == null) {
        continue;
      }
      grouped
          .putIfAbsent(location.parent, () => <_DetachedNode<T>>[])
          .add(_DetachedNode<T>(node: node, index: location.index));
    }

    for (final MapEntry<TreeNode<T>?, List<_DetachedNode<T>>> entry
        in grouped.entries) {
      final TreeNode<T>? parent = entry.key;
      final List<_DetachedNode<T>> nodes = entry.value
        ..sort((a, b) => a.index.compareTo(b.index));

      if (parent == null) {
        for (final _DetachedNode<T> detached in nodes) {
          final int safeIndex = detached.index.clamp(0, _roots.length);
          detached.node.parent = null;
          _roots.insert(safeIndex, detached.node);
        }
      } else {
        for (final _DetachedNode<T> detached in nodes) {
          final int safeIndex = detached.index.clamp(0, parent.children.length);
          parent.internalInsertChild(safeIndex, detached.node);
        }
      }
    }
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
