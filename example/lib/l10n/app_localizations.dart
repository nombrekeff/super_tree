import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Super Tree Examples'**
  String get appTitle;

  /// No description provided for @quickLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinksTitle;

  /// No description provided for @allExamplesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Examples'**
  String get allExamplesTitle;

  /// No description provided for @exampleFileSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'File System Explorer'**
  String get exampleFileSystemTitle;

  /// No description provided for @exampleFileSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'The classic file explorer example with drag and drop and multiple presets (VS Code, Material, Compact).'**
  String get exampleFileSystemDescription;

  /// No description provided for @exampleCheckboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkboxes and State'**
  String get exampleCheckboxTitle;

  /// No description provided for @exampleCheckboxDescription.
  ///
  /// In en, this message translates to:
  /// **'A permissions tree demonstrating checkboxes with recursive parent and child state management.'**
  String get exampleCheckboxDescription;

  /// No description provided for @exampleComplexNodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Complex Node UI'**
  String get exampleComplexNodeTitle;

  /// No description provided for @exampleComplexNodeDescription.
  ///
  /// In en, this message translates to:
  /// **'A task management board showing rich custom node content, avatars, and inline actions.'**
  String get exampleComplexNodeDescription;

  /// No description provided for @exampleTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'Todo List Tree'**
  String get exampleTodoTitle;

  /// No description provided for @exampleTodoDescription.
  ///
  /// In en, this message translates to:
  /// **'A prebuilt convenience tree view demonstrating default checkboxes, data models, and sorting logic for a hierarchical todo list.'**
  String get exampleTodoDescription;

  /// No description provided for @exampleSimpleFileSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimal File System'**
  String get exampleSimpleFileSystemTitle;

  /// No description provided for @exampleSimpleFileSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'A minimalist example showing how to build a file tree with zero boilerplate and hardcoded data.'**
  String get exampleSimpleFileSystemDescription;

  /// No description provided for @exampleAsyncLazyTitle.
  ///
  /// In en, this message translates to:
  /// **'Async Lazy Loading'**
  String get exampleAsyncLazyTitle;

  /// No description provided for @exampleAsyncLazyDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows on-demand child loading with spinner and error retry states when expanding nodes.'**
  String get exampleAsyncLazyDescription;

  /// No description provided for @exampleIntegrityTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrity Guardrails'**
  String get exampleIntegrityTitle;

  /// No description provided for @exampleIntegrityDescription.
  ///
  /// In en, this message translates to:
  /// **'Demonstrates duplicate-ID and circular-reference safety checks with non-fatal UI warnings.'**
  String get exampleIntegrityDescription;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearSearch;

  /// No description provided for @searchCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close search (Esc)'**
  String get searchCloseTooltip;

  /// No description provided for @todoScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Todo List Tree'**
  String get todoScreenTitle;

  /// No description provided for @todoSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search todos (Cmd/Ctrl+F)'**
  String get todoSearchTooltip;

  /// No description provided for @todoResortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Re-sort Tree'**
  String get todoResortTooltip;

  /// No description provided for @todoSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search todo title, done, or pending'**
  String get todoSearchHint;

  /// No description provided for @todoDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get todoDelete;

  /// No description provided for @todoNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String todoNoResults(Object query);

  /// No description provided for @todoClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get todoClearSearch;

  /// No description provided for @todoDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Todo List Example'**
  String get todoDetailTitle;

  /// No description provided for @todoDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try checking off items to see them strike through.\\nDrag and drop items to reorganize your tasks.'**
  String get todoDetailSubtitle;

  /// No description provided for @fileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'File System Tree'**
  String get fileScreenTitle;

  /// No description provided for @fileSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search files and folders'**
  String get fileSearchHint;

  /// No description provided for @fileSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search (Cmd/Ctrl+F)'**
  String get fileSearchTooltip;

  /// No description provided for @fileSortNone.
  ///
  /// In en, this message translates to:
  /// **'No Sort'**
  String get fileSortNone;

  /// No description provided for @fileSortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get fileSortAlphabetical;

  /// No description provided for @fileSortFoldersFirst.
  ///
  /// In en, this message translates to:
  /// **'Folders First'**
  String get fileSortFoldersFirst;

  /// No description provided for @fileThemeVsCode.
  ///
  /// In en, this message translates to:
  /// **'VS Code Dark'**
  String get fileThemeVsCode;

  /// No description provided for @fileThemeMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get fileThemeMaterial;

  /// No description provided for @fileThemeCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get fileThemeCompact;

  /// No description provided for @fileActionNewRootFolder.
  ///
  /// In en, this message translates to:
  /// **'New Root Folder'**
  String get fileActionNewRootFolder;

  /// No description provided for @fileActionNewRootFile.
  ///
  /// In en, this message translates to:
  /// **'New Root File'**
  String get fileActionNewRootFile;

  /// No description provided for @fileActionExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand All'**
  String get fileActionExpandAll;

  /// No description provided for @fileActionCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse All'**
  String get fileActionCollapseAll;

  /// No description provided for @fileRootMenuNewFile.
  ///
  /// In en, this message translates to:
  /// **'New File'**
  String get fileRootMenuNewFile;

  /// No description provided for @fileRootMenuNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get fileRootMenuNewFolder;

  /// No description provided for @fileRootMenuExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand All'**
  String get fileRootMenuExpandAll;

  /// No description provided for @fileRootMenuCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse All'**
  String get fileRootMenuCollapseAll;

  /// No description provided for @fileNodeMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fileNodeMenuRename;

  /// No description provided for @fileNodeMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fileNodeMenuDelete;

  /// No description provided for @fileNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String fileNoResults(Object query);

  /// No description provided for @fileSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select a file to view\\nDrag and drop nodes to move them'**
  String get fileSelectHint;

  /// No description provided for @fileItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String fileItemsSelected(int count);

  /// No description provided for @fileDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Items'**
  String get fileDeleteSelected;

  /// No description provided for @fileTypeFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get fileTypeFolder;

  /// No description provided for @fileTypeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileTypeFile;

  /// No description provided for @fileRenameItem.
  ///
  /// In en, this message translates to:
  /// **'Rename Item'**
  String get fileRenameItem;

  /// No description provided for @fileRenamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String fileRenamedTo(Object name);

  /// No description provided for @fileItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get fileItemDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
