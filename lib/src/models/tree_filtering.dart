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

/// Extra query matcher hook used by [FuzzyTreeFilter] before the default matcher.
typedef TreeFilterCustomMatcher<T> = TreeFuzzyMatchResult? Function(
  String normalizedQuery,
  TreeNode<T> node,
  String candidate,
);

/// Maps specific query keywords to a node predicate result.
class TreeFilterKeywordRule<T> {
  const TreeFilterKeywordRule({
    required this.keywords,
    required this.predicate,
    this.matchResult = const TreeFuzzyMatchResult(score: 0, matchedIndices: <int>[]),
  });

  /// Keywords expected in lowercase trimmed format.
  final Set<String> keywords;

  /// Determines whether the node is considered a match for [keywords].
  final bool Function(TreeNode<T> node) predicate;

  /// Match payload to return when [predicate] succeeds.
  final TreeFuzzyMatchResult matchResult;

  TreeFuzzyMatchResult? match(String normalizedQuery, TreeNode<T> node) {
    if (!keywords.contains(normalizedQuery)) {
      return null;
    }
    if (!predicate(node)) {
      return null;
    }
    return matchResult;
  }
}

/// Reusable matcher builder that combines keyword rules, custom matchers,
/// and the default ordered-character fuzzy matcher.
class FuzzyTreeFilter<T> {
  FuzzyTreeFilter({
    this.fuzzyMatcher = defaultTreeFuzzyMatcher,
    List<TreeFilterKeywordRule<T>>? keywordRules,
    List<TreeFilterCustomMatcher<T>>? customMatchers,
  }) : keywordRules = List<TreeFilterKeywordRule<T>>.unmodifiable(
         keywordRules ?? <TreeFilterKeywordRule<T>>[],
       ),
       customMatchers = List<TreeFilterCustomMatcher<T>>.unmodifiable(
         customMatchers ?? <TreeFilterCustomMatcher<T>>[],
       );

  final TreeFuzzyMatcher fuzzyMatcher;
  final List<TreeFilterKeywordRule<T>> keywordRules;
  final List<TreeFilterCustomMatcher<T>> customMatchers;

  /// Resolves a match result for the [query]/[node]/[candidate] tuple.
  TreeFuzzyMatchResult? match(
    String query,
    TreeNode<T> node,
    String candidate,
  ) {
    final String normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const TreeFuzzyMatchResult(score: 0, matchedIndices: <int>[]);
    }

    final String normalizedCandidate = candidate.toLowerCase();

    for (final TreeFilterKeywordRule<T> rule in keywordRules) {
      final TreeFuzzyMatchResult? ruleMatch = rule.match(normalizedQuery, node);
      if (ruleMatch != null) {
        return ruleMatch;
      }
    }

    for (final TreeFilterCustomMatcher<T> matcher in customMatchers) {
      final TreeFuzzyMatchResult? customMatch = matcher(
        normalizedQuery,
        node,
        normalizedCandidate,
      );
      if (customMatch != null) {
        return customMatch;
      }
    }

    return fuzzyMatcher(normalizedQuery, normalizedCandidate);
  }

  /// Adapter for plugging this filter directly into `TreeSearchController.searchMatcher`.
  TreeFuzzyMatchResult? Function(String, TreeNode<T>, String) asSearchMatcher() {
    return (
      String query,
      TreeNode<T> node,
      String candidate,
    ) {
      return match(query, node, candidate);
    };
  }

  /// Helper custom matcher for extension-based search terms (e.g. `.dart`).
  static TreeFilterCustomMatcher<T> extensionSuffixMatcher<T>({
    bool Function(TreeNode<T> node)? nodePredicate,
  }) {
    return (
      String normalizedQuery,
      TreeNode<T> node,
      String candidate,
    ) {
      if (!normalizedQuery.startsWith('.')) {
        return null;
      }
      if (nodePredicate != null && !nodePredicate(node)) {
        return null;
      }
      if (!candidate.endsWith(normalizedQuery)) {
        return null;
      }

      final int start = candidate.length - normalizedQuery.length;
      return TreeFuzzyMatchResult(
        score: 0,
        matchedIndices: List<int>.generate(
          normalizedQuery.length,
          (int i) => start + i,
        ),
      );
    };
  }
}

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
