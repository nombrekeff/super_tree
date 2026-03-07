import 'package:super_tree/src/models/tree_node.dart';

/// Predicate used to include/exclude nodes during filtering.
typedef TreeNodeFilter<T> = bool Function(TreeNode<T> node);

/// Label extractor used by query-based filtering.
typedef TreeSearchLabelProvider<T> = String Function(T data);

/// Query matcher that can use node metadata and label text.
typedef TreeNodeQueryMatcher<T> = TreeFuzzyMatchResult? Function(
  String query,
  TreeNode<T> node,
  String candidate,
);

/// Match metadata used to drive fuzzy-search highlighting.
class TreeFuzzyMatchResult {
  const TreeFuzzyMatchResult({
    required this.score,
    required this.matchedIndices,
  });

  final int score;
  final List<int> matchedIndices;
}

/// Signature for custom fuzzy match algorithms.
typedef TreeFuzzyMatcher = TreeFuzzyMatchResult? Function(String query, String candidate);

/// Expansion behavior to use while a search query is active.
enum TreeSearchExpansionBehavior {
  none,
  expandMatches,
  expandAncestors,
  expandMatchesAndAncestors,
}

/// Default ordered-character fuzzy matcher.
///
/// Returns `null` when [query] cannot be found in [candidate] in order.
/// Lower scores are better.
TreeFuzzyMatchResult? defaultTreeFuzzyMatcher(String query, String candidate) {
  if (query.isEmpty) {
    return const TreeFuzzyMatchResult(score: 0, matchedIndices: <int>[]);
  }

  final String lowerQuery = query.toLowerCase();
  final String lowerCandidate = candidate.toLowerCase();

  int queryIndex = 0;
  int score = 0;
  int lastMatchIndex = -1;
  final List<int> matches = <int>[];

  for (int i = 0; i < lowerCandidate.length && queryIndex < lowerQuery.length; i++) {
    if (lowerCandidate[i] == lowerQuery[queryIndex]) {
      matches.add(i);
      if (lastMatchIndex >= 0) {
        score += (i - lastMatchIndex - 1);
      }
      lastMatchIndex = i;
      queryIndex++;
    }
  }

  if (queryIndex != lowerQuery.length) {
    return null;
  }

  // Slightly prefer shorter labels when match quality is identical.
  score += (lowerCandidate.length - lowerQuery.length);

  return TreeFuzzyMatchResult(score: score, matchedIndices: matches);
}
