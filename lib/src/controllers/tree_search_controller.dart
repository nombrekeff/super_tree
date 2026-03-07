import 'package:flutter/foundation.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/models/tree_filtering.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Optional callback to provide custom expansion behavior during search.
typedef TreeSearchExpansionStrategy<T> = void Function(
  TreeController<T> controller,
  Set<String> matchedNodeIds,
);

/// Optional callback to provide custom search matching behavior.
typedef TreeSearchMatcher<T> = TreeFuzzyMatchResult? Function(
  String query,
  TreeNode<T> node,
  String candidate,
);

/// Coordinates query filtering and expansion behavior for a [TreeController].
class TreeSearchController<T> extends ChangeNotifier {
  TreeSearchController({
    required this.treeController,
    required this.labelProvider,
    this.baseFilter,
    this.searchMatcher,
    this.fuzzyMatcher = defaultTreeFuzzyMatcher,
    this.expansionBehavior = TreeSearchExpansionBehavior.expandAncestors,
    this.expansionStrategy,
    this.restoreExpansionOnClear = true,
  });

  final TreeController<T> treeController;
  final TreeSearchLabelProvider<T> labelProvider;
  final TreeNodeFilter<T>? baseFilter;
  final TreeSearchMatcher<T>? searchMatcher;
  final TreeFuzzyMatcher fuzzyMatcher;
  final TreeSearchExpansionBehavior expansionBehavior;
  final TreeSearchExpansionStrategy<T>? expansionStrategy;
  final bool restoreExpansionOnClear;

  String _query = '';
  Map<String, bool>? _expansionSnapshot;

  String get query => _query;
  bool get hasQuery => _query.isNotEmpty;

  /// Applies query search and updates the associated [treeController].
  void search(String nextQuery) {
    final String normalized = nextQuery.trim();
    if (normalized == _query) {
      return;
    }

    if (normalized.isEmpty) {
      clearSearch();
      return;
    }

    if (_query.isEmpty) {
      _captureExpansionSnapshot();
    }

    _query = normalized;
    final _SearchMatchComputation computation = _collectMatches(_query);
    _applyExpansion(computation.matchedNodeIds);

    treeController.applyFilter(
      predicate: (TreeNode<T> node) => computation.matchedNodeIds.contains(node.id),
      matchedIndicesByNodeId: computation.matchedIndicesByNodeId,
    );

    notifyListeners();
  }

  /// Clears search and optionally restores expansion state.
  void clearSearch() {
    if (_query.isEmpty && _expansionSnapshot == null) {
      return;
    }

    _query = '';

    if (baseFilter != null) {
      treeController.applyFilter(predicate: baseFilter!);
    } else {
      treeController.clearFilter();
    }

    if (restoreExpansionOnClear) {
      _restoreExpansionSnapshot();
      treeController.notifyListeners();
    }

    _expansionSnapshot = null;
    notifyListeners();
  }

  TreeNodeQueryMatcher<T> _buildNodeMatcher() {
    return (
      String query,
      TreeNode<T> node,
      String candidate,
    ) {
      if (searchMatcher != null) {
        return searchMatcher!(query, node, candidate);
      }
      return fuzzyMatcher(query, candidate);
    };
  }

  _SearchMatchComputation _collectMatches(String query) {
    final Set<String> matchedNodeIds = <String>{};
    final Map<String, List<int>> matchedIndicesByNodeId = <String, List<int>>{};
    final TreeNodeQueryMatcher<T> matcher = _buildNodeMatcher();

    void visit(TreeNode<T> node) {
      if (baseFilter == null || baseFilter!.call(node)) {
        final String label = labelProvider(node.data);
        final TreeFuzzyMatchResult? match = matcher(query, node, label);
        if (match != null) {
          matchedNodeIds.add(node.id);
          matchedIndicesByNodeId[node.id] = List<int>.from(match.matchedIndices);
        }
      }

      for (final TreeNode<T> child in node.children) {
        visit(child);
      }
    }

    for (final TreeNode<T> root in treeController.roots) {
      visit(root);
    }

    return _SearchMatchComputation(
      matchedNodeIds: matchedNodeIds,
      matchedIndicesByNodeId: matchedIndicesByNodeId,
    );
  }

  void _captureExpansionSnapshot() {
    final Map<String, bool> snapshot = <String, bool>{};

    void visit(TreeNode<T> node) {
      snapshot[node.id] = node.isExpanded;
      for (final TreeNode<T> child in node.children) {
        visit(child);
      }
    }

    for (final TreeNode<T> root in treeController.roots) {
      visit(root);
    }

    _expansionSnapshot = snapshot;
  }

  void _restoreExpansionSnapshot() {
    final Map<String, bool>? snapshot = _expansionSnapshot;
    if (snapshot == null) {
      return;
    }

    void visit(TreeNode<T> node) {
      final bool? value = snapshot[node.id];
      if (value != null) {
        node.isExpanded = value;
      }
      for (final TreeNode<T> child in node.children) {
        visit(child);
      }
    }

    for (final TreeNode<T> root in treeController.roots) {
      visit(root);
    }
  }

  void _applyExpansion(Set<String> matchedNodeIds) {
    if (expansionStrategy != null) {
      expansionStrategy!(treeController, matchedNodeIds);
      return;
    }

    switch (expansionBehavior) {
      case TreeSearchExpansionBehavior.none:
        return;
      case TreeSearchExpansionBehavior.expandMatches:
        _expandMatches(matchedNodeIds);
        return;
      case TreeSearchExpansionBehavior.expandAncestors:
        _expandAncestors(matchedNodeIds);
        return;
      case TreeSearchExpansionBehavior.expandMatchesAndAncestors:
        _expandAncestors(matchedNodeIds);
        _expandMatches(matchedNodeIds);
        return;
    }
  }

  void _expandMatches(Set<String> matchedNodeIds) {
    for (final String id in matchedNodeIds) {
      final TreeNode<T>? node = treeController.findNodeById(id);
      if (node != null && node.hasChildren) {
        node.isExpanded = true;
      }
    }
  }

  void _expandAncestors(Set<String> matchedNodeIds) {
    for (final String id in matchedNodeIds) {
      TreeNode<T>? cursor = treeController.findNodeById(id)?.parent;
      while (cursor != null) {
        cursor.isExpanded = true;
        cursor = cursor.parent;
      }
    }
  }
}

class _SearchMatchComputation {
  const _SearchMatchComputation({
    required this.matchedNodeIds,
    required this.matchedIndicesByNodeId,
  });

  final Set<String> matchedNodeIds;
  final Map<String, List<int>> matchedIndicesByNodeId;
}
