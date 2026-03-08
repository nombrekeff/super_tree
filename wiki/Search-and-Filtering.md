# Search & Filtering

`super_tree` ships with a composable search and filtering system built around two classes: `TreeSearchController` and `FuzzyTreeFilter`. Together they support fuzzy text search, keyword shortcuts (e.g. `done`, `pending`), file extension matching, and fully custom matcher logic.

---

## How it works

1. `TreeSearchController` holds the active query and orchestrates expansions.
2. When a query changes it calls a matcher function on every node.
3. Nodes that match — plus all their ancestors — are passed to `TreeController.applyFilter`.
4. The UI renders only those nodes; `TreeHighlightedLabel` renders character-level highlights.

---

## TreeSearchController

### Constructor

```dart
TreeSearchController<T>({
  required TreeController<T> treeController,
  required TreeSearchLabelProvider<T> labelProvider, // (T data) => String
  TreeNodeFilter<T>? baseFilter,         // persistent base filter
  TreeSearchMatcher<T>? searchMatcher,   // override the default matcher
  TreeFuzzyMatcher fuzzyMatcher = defaultTreeFuzzyMatcher,
  TreeSearchExpansionBehavior expansionBehavior =
      TreeSearchExpansionBehavior.expandAncestors,
  TreeSearchExpansionStrategy<T>? expansionStrategy, // custom expansion hook
  bool restoreExpansionOnClear = true,
})
```

### Usage

```dart
final searchController = TreeSearchController<FileSystemItem>(
  treeController: _controller,
  labelProvider: (item) => item.name,
  expansionBehavior: TreeSearchExpansionBehavior.expandAncestors,
);

// Trigger a search
searchController.search('main');

// Clear and restore expansion state
searchController.clearSearch();
```

Listen to the `TreeSearchController` just like any `ChangeNotifier`:

```dart
searchController.addListener(() {
  print('Query: ${searchController.query}');
  print('Has query: ${searchController.hasQuery}');
});
```

### Connecting to a TextField

```dart
TextField(
  onChanged: searchController.search,
  decoration: InputDecoration(
    hintText: 'Search…',
    suffixIcon: searchController.hasQuery
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: searchController.clearSearch,
          )
        : null,
  ),
)
```

### TreeSearchExpansionBehavior

| Value | Behaviour |
|-------|-----------|
| `none` | Expansion state is not changed during search |
| `expandMatches` | Expand nodes that directly match the query |
| `expandAncestors` | Expand all ancestors of matching nodes |
| `expandMatchesAndAncestors` | Expand both matching nodes and their ancestors |

### restoreExpansionOnClear

When `true` (default), the expansion state before the search started is restored when `clearSearch()` is called. Set to `false` to keep the post-search expansion.

---

## FuzzyTreeFilter

`FuzzyTreeFilter` is a composable match resolver. It runs rules in priority order:

1. **Keyword rules** — exact keyword → predicate match
2. **Custom matchers** — arbitrary logic
3. **Default fuzzy matcher** — ordered-character subsequence matching

### Constructor

```dart
FuzzyTreeFilter<T>({
  List<TreeFilterKeywordRule<T>>? keywordRules,
  List<TreeFilterCustomMatcher<T>>? customMatchers,
  TreeFuzzyMatcher fuzzyMatcher = defaultTreeFuzzyMatcher,
})
```

### Keyword rules

Map specific search terms to node predicates:

```dart
final filter = FuzzyTreeFilter<TodoItem>(
  keywordRules: [
    TreeFilterKeywordRule<TodoItem>(
      keywords: {'done', 'completed'},
      predicate: (node) => node.data.isCompleted,
    ),
    TreeFilterKeywordRule<TodoItem>(
      keywords: {'open', 'pending', 'todo'},
      predicate: (node) => !node.data.isCompleted,
    ),
  ],
);
```

When the query exactly matches a keyword (case-insensitive) and the predicate returns `true`, the node is considered a match — no fuzzy matching is attempted.

### Custom matchers

Add arbitrary match logic before the default fuzzy algorithm:

```dart
final filter = FuzzyTreeFilter<FileSystemItem>(
  customMatchers: [
    // match nodes by file extension, e.g. ".dart"
    FuzzyTreeFilter.extensionSuffixMatcher<FileSystemItem>(
      nodePredicate: (node) => node.data.isFile,
    ),
  ],
);
```

`FuzzyTreeFilter.extensionSuffixMatcher` is a built-in helper that matches query strings starting with `.` against the file extension of the candidate label.

### Plugging into TreeSearchController

```dart
final searchController = TreeSearchController<FileSystemItem>(
  treeController: _controller,
  labelProvider: (item) => item.name,
  searchMatcher: filter.asSearchMatcher(),
);
```

`asSearchMatcher()` adapts the filter to the `TreeSearchMatcher<T>` signature expected by `TreeSearchController`.

---

## Default fuzzy matcher

`defaultTreeFuzzyMatcher` is the built-in algorithm. It does an ordered-character subsequence match:

- Matches if every character in the query appears in the candidate in order.
- Scores gaps between consecutive matches (lower = better).
- Slightly prefers shorter labels when scores tie.
- Returns `null` when no match is found.

You can replace it entirely:

```dart
TreeSearchController<T>(
  fuzzyMatcher: (query, candidate) {
    // your custom algorithm, return TreeFuzzyMatchResult? or null
    return candidate.contains(query)
        ? TreeFuzzyMatchResult(score: 0, matchedIndices: [])
        : null;
  },
  ...
)
```

---

## Highlighting matched characters

Use `TreeHighlightedLabel` in `contentBuilder` to highlight the matched indices:

```dart
contentBuilder: (context, node, renameField) {
  if (renameField != null) return renameField;
  return TreeHighlightedLabel(
    label: node.data.name,
    matchedIndices: _controller.getMatchedIndices(node.id),
  );
},
```

`TreeController.getMatchedIndices(nodeId)` returns the character positions to highlight (populated by `TreeSearchController` during a search).

---

## Edge cases

| Scenario | Behaviour |
|----------|-----------|
| Empty query | `FuzzyTreeFilter.match` returns a zero-score empty-highlight result. Call `searchController.clearSearch()` to restore unfiltered state. |
| No matching nodes | The filter stays active; no nodes are shown until the query changes or is cleared. |
| Base filter + search | Set `baseFilter` on `TreeSearchController` — it is re-applied when the search is cleared, so persistent filters survive query changes. |

---

## Complete example

```dart
class _SearchExampleState extends State<SearchExample> {
  late final TreeController<FileSystemItem> _controller;
  late final TreeSearchController<FileSystemItem> _searchController;
  late final FuzzyTreeFilter<FileSystemItem> _filter;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<FileSystemItem>(roots: _buildTree());

    _filter = FuzzyTreeFilter<FileSystemItem>(
      customMatchers: [
        FuzzyTreeFilter.extensionSuffixMatcher(
          nodePredicate: (node) => node.data.isFile,
        ),
      ],
    );

    _searchController = TreeSearchController<FileSystemItem>(
      treeController: _controller,
      labelProvider: (item) => item.name,
      searchMatcher: _filter.asSearchMatcher(),
      expansionBehavior: TreeSearchExpansionBehavior.expandAncestors,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            onChanged: _searchController.search,
            decoration: const InputDecoration(
              hintText: 'Search files…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: SuperTreeView<FileSystemItem>(
            controller: _controller,
            prefixBuilder: (context, node) => Icon(
              node.data.isDirectory ? Icons.folder : Icons.insert_drive_file,
            ),
            contentBuilder: (context, node, renameField) {
              if (renameField != null) return renameField;
              return TreeHighlightedLabel(
                label: node.data.name,
                matchedIndices: _controller.getMatchedIndices(node.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

---

## See also

- [TreeController](TreeController) — `applyFilter`, `clearFilter`, `getMatchedIndices`
- [SuperTreeView](SuperTreeView) — `labelProvider` and `contentBuilder`
- [TreeNode](TreeNode) — node model and data types
