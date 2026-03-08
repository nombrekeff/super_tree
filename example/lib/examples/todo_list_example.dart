import 'package:flutter/material.dart';
import 'package:example/examples/shared/example_tree_search_bar.dart';
import 'package:example/examples/shared/example_tree_search_logic.dart';
import 'package:example/examples/shared/example_tree_search_shortcuts.dart';
import 'package:example/l10n/app_localizations.dart';
import 'package:super_tree/super_tree.dart';

class TodoListExample extends StatefulWidget {
  const TodoListExample({super.key});

  @override
  State<TodoListExample> createState() => _TodoListExampleState();
}

class _TodoListExampleState extends State<TodoListExample> {
  late final TreeController<TodoItem> _controller;
  late final TreeSearchController<TodoItem> _searchController;
  late final ExampleTreeSearchLogic<TodoItem> _searchUi;
  late final FuzzyTreeFilter<TodoItem> _todoSearchFilter;

  @override
  void initState() {
    super.initState();
    _controller = TreeController<TodoItem>(
      roots: [
        TreeNode(
          data: TodoItem('Work Tasks'),
          isExpanded: true,
          children: [
            TreeNode(data: TodoItem('Review PRs', isCompleted: true)),
            TreeNode(
              data: TodoItem('Write Documentation'),
              children: [
                TreeNode(data: TodoItem('Update README')),
                TreeNode(data: TodoItem('Add inline comments', isCompleted: true)),
              ],
              isExpanded: true,
            ),
            TreeNode(data: TodoItem('Fix issue #42')),
          ],
        ),
        TreeNode(
          data: TodoItem('Personal'),
          isExpanded: true,
          children: [
            TreeNode(
              data: TodoItem('Buy groceries'),
              children: [
                TreeNode(data: TodoItem('Milk')),
                TreeNode(data: TodoItem('Eggs')),
                TreeNode(data: TodoItem('Bread', isCompleted: true)),
              ],
              isExpanded: true,
            ),
            TreeNode(data: TodoItem('Call mom')),
          ],
        ),
      ],
    );

    _todoSearchFilter = FuzzyTreeFilter<TodoItem>(
      keywordRules: <TreeFilterKeywordRule<TodoItem>>[
        TreeFilterKeywordRule<TodoItem>(
          keywords: <String>{'done', 'completed'},
          predicate: (TreeNode<TodoItem> node) => node.data.isCompleted,
        ),
        TreeFilterKeywordRule<TodoItem>(
          keywords: <String>{'open', 'pending'},
          predicate: (TreeNode<TodoItem> node) => !node.data.isCompleted,
        ),
      ],
    );

    _searchController = TreeSearchController<TodoItem>(
      treeController: _controller,
      labelProvider: (TodoItem item) => item.title,
      expansionBehavior: TreeSearchExpansionBehavior.expandAncestors,
      searchMatcher: _todoSearchFilter.asSearchMatcher(),
    );
    _searchUi = ExampleTreeSearchLogic<TodoItem>(searchController: _searchController);
  }

  @override
  void dispose() {
    _searchUi.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openSearch() {
    _searchUi.open(refresh: _refreshSearchUi);
  }

  void _closeSearch() {
    _searchUi.close(refresh: _refreshSearchUi);
  }

  void _handleSearchChanged(String value) {
    _searchUi.handleChanged(value);
  }

  void _refreshSearchUi() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _refreshTodoOrder() {
    // Rebuild to apply current sort/grouping visual order after model changes.
    setState(() {});
  }

  Widget _buildCompactHeaderTitle(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.checklist_rtl, size: 18),
        const SizedBox(width: 8),
        Text(l10n.todoScreenTitle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool noSearchResults =
        _searchController.hasQuery && _controller.flatVisibleNodes.isEmpty;
    final ThemeData theme = Theme.of(context);
    final Widget headerTitle = _buildCompactHeaderTitle(l10n);

    return ExampleTreeSearchShortcuts(
      onOpenSearch: _openSearch,
      onCloseSearch: _closeSearch,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          titleSpacing: 12,
          centerTitle: false,
          title: headerTitle,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          scrolledUnderElevation: 0,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.todoSearchTooltip,
              onPressed: _openSearch,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.todoResortTooltip,
              onPressed: _refreshTodoOrder,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            if (_searchUi.isSearchVisible)
              ExampleTreeSearchBar(
                controller: _searchUi.textController,
                focusNode: _searchUi.focusNode,
                onChanged: _handleSearchChanged,
                onClose: _closeSearch,
                hasQuery: _searchController.hasQuery,
                hintText: l10n.todoSearchHint,
                clearLabel: l10n.searchClear,
                closeTooltip: l10n.searchCloseTooltip,
                hideBorder: true,
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TodoListSuperTree(
                      controller: _controller,
                      style: const TreeViewStyle(
                        indentAmount: 24.0,
                        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                      ),
                      logic: const TreeViewConfig(
                        expansionTrigger: ExpansionTrigger.tap,
                      ),
                      onTodoChanged: (item) {
                        // We call setState so the checkbox visuals update.
                        // Depending on the implementation, you could also manually call _controller.rebuild()
                        // to force immediate visual re-sorting of the tree if desired.
                        setState(() {});
                      },
                      contextMenuBuilder: (context, node) {
                        return [
                          ContextMenuItem(
                            child: Text(l10n.todoDelete),
                            onTap: () {
                              _controller.removeNode(node);
                            },
                          ),
                        ];
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (noSearchResults) ...[
                            const Icon(Icons.search_off, size: 64),
                            const SizedBox(height: 12),
                            Text(l10n.todoNoResults(_searchController.query)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _closeSearch,
                              child: Text(l10n.searchClearSearch),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Icon(
                            Icons.checklist,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.todoDetailTitle,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.todoDetailSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
