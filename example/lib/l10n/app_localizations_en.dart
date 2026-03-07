// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Super Tree Examples';

  @override
  String get quickLinksTitle => 'Quick Links';

  @override
  String get allExamplesTitle => 'All Examples';

  @override
  String get exampleFileSystemTitle => 'File System Explorer';

  @override
  String get exampleFileSystemDescription =>
      'The classic file explorer example with drag and drop and multiple presets (VS Code, Material, Compact).';

  @override
  String get exampleCheckboxTitle => 'Checkboxes and State';

  @override
  String get exampleCheckboxDescription =>
      'A permissions tree demonstrating checkboxes with recursive parent and child state management.';

  @override
  String get exampleComplexNodeTitle => 'Complex Node UI';

  @override
  String get exampleComplexNodeDescription =>
      'A task management board showing rich custom node content, avatars, and inline actions.';

  @override
  String get exampleTodoTitle => 'Todo List Tree';

  @override
  String get exampleTodoDescription =>
      'A prebuilt convenience tree view demonstrating default checkboxes, data models, and sorting logic for a hierarchical todo list.';

  @override
  String get exampleSimpleFileSystemTitle => 'Minimal File System';

  @override
  String get exampleSimpleFileSystemDescription =>
      'A minimalist example showing how to build a file tree with zero boilerplate and hardcoded data.';

  @override
  String get exampleAsyncLazyTitle => 'Async Lazy Loading';

  @override
  String get exampleAsyncLazyDescription =>
      'Shows on-demand child loading with spinner and error retry states when expanding nodes.';

  @override
  String get exampleIntegrityTitle => 'Integrity Guardrails';

  @override
  String get exampleIntegrityDescription =>
      'Demonstrates duplicate-ID and circular-reference safety checks with non-fatal UI warnings.';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchClearSearch => 'Clear search';

  @override
  String get searchCloseTooltip => 'Close search (Esc)';

  @override
  String get todoScreenTitle => 'Todo List Tree';

  @override
  String get todoSearchTooltip => 'Search todos (Cmd/Ctrl+F)';

  @override
  String get todoResortTooltip => 'Re-sort Tree';

  @override
  String get todoSearchHint => 'Search todo title, done, or pending';

  @override
  String get todoDelete => 'Delete';

  @override
  String todoNoResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get todoClearSearch => 'Clear search';

  @override
  String get todoDetailTitle => 'Todo List Example';

  @override
  String get todoDetailSubtitle =>
      'Try checking off items to see them strike through.\\nDrag and drop items to reorganize your tasks.';

  @override
  String get fileScreenTitle => 'File System Tree';

  @override
  String get fileSearchHint => 'Search files and folders';

  @override
  String get fileSearchTooltip => 'Search (Cmd/Ctrl+F)';

  @override
  String get fileSortNone => 'No Sort';

  @override
  String get fileSortAlphabetical => 'Alphabetical';

  @override
  String get fileSortFoldersFirst => 'Folders First';

  @override
  String get fileThemeVsCode => 'VS Code Dark';

  @override
  String get fileThemeMaterial => 'Material';

  @override
  String get fileThemeCompact => 'Compact';

  @override
  String get fileActionNewRootFolder => 'New Root Folder';

  @override
  String get fileActionNewRootFile => 'New Root File';

  @override
  String get fileActionExpandAll => 'Expand All';

  @override
  String get fileActionCollapseAll => 'Collapse All';

  @override
  String get fileRootMenuNewFile => 'New File';

  @override
  String get fileRootMenuNewFolder => 'New Folder';

  @override
  String get fileRootMenuExpandAll => 'Expand All';

  @override
  String get fileRootMenuCollapseAll => 'Collapse All';

  @override
  String get fileNodeMenuRename => 'Rename';

  @override
  String get fileNodeMenuDelete => 'Delete';

  @override
  String fileNoResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get fileSelectHint =>
      'Select a file to view\\nDrag and drop nodes to move them';

  @override
  String fileItemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get fileDeleteSelected => 'Delete Selected Items';

  @override
  String get fileTypeFolder => 'Folder';

  @override
  String get fileTypeFile => 'File';

  @override
  String get fileRenameItem => 'Rename Item';

  @override
  String fileRenamedTo(Object name) {
    return 'Renamed to $name';
  }

  @override
  String get fileItemDeleted => 'Item deleted';
}
