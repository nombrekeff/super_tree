# Copilot Instructions for super_tree

## Project Overview

`super_tree` is a high-performance, fully customizable, hierarchical tree view Flutter package. It provides `SuperTreeView`, a flat-list-backed widget for building tree UIs such as file explorers, todo lists, and permission trees. The package targets both desktop and mobile platforms and provides built-in support for keyboard navigation, right-click/long-press context menus, drag-and-drop, fuzzy search, and multi-selection.

## Repository Layout

```
lib/
  super_tree.dart          # Public barrel export
  src/
    configs/               # Configuration/option classes (e.g. TreeConfig)
    controllers/           # TreeController, TreeSearchController, state logic
    models/                # TreeNode and related data models
    widgets/               # Flutter widgets (SuperTreeView, builders, etc.)
example/
  lib/                     # Runnable example app demonstrating package features
test/
  controllers_test.dart    # Unit tests for controllers
  widgets_test.dart        # Widget tests for SuperTreeView
```

## Development Environment

- **Language**: Dart (Flutter SDK)
- **Dart SDK**: `^3.9.2`
- **Flutter SDK**: stable channel (the Dart 3.9.x constraint requires a recent stable Flutter release)
- **Package manager**: `pub` (via `flutter pub`)

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run a specific test file
flutter test test/controllers_test.dart

# Analyze code (lint)
dart analyze

# Format code
dart format lib test

# Generate API docs
dart doc --output doc/api

# Run the example app (requires a connected device or emulator)
cd example && flutter run
```

## Code Style & Conventions

This project enforces a strict set of Dart/Flutter lint rules via `analysis_options.yaml` (extending `flutter_lints`). Key rules to follow:

- Use **single quotes** for strings (`prefer_single_quotes`).
- Always declare **return types** (`always_declare_return_types`).
- Use `const` constructors and declarations wherever possible (`prefer_const_constructors`, `prefer_const_declarations`).
- Use `final` for locals and fields that are not reassigned (`prefer_final_locals`, `prefer_final_fields`).
- Use `///` (triple-slash) for all documentation comments (`slash_for_doc_comments`).
- Annotate all `@override` methods (`annotate_overrides`).
- Always use curly braces in flow-control statements (`curly_braces_in_flow_control_structures`).
- Use generic function type aliases instead of `typedef` (`prefer_generic_function_type_aliases`).
- Prefer collection literals over constructors (`prefer_collection_literals`).
- Avoid `new` keyword (`unnecessary_new`).

Run `dart analyze` after every change to catch lint violations before committing.

## Testing Guidelines

- Tests live in `test/`. Use `flutter test` to run them.
- **Controller logic** belongs in `controllers_test.dart` (pure Dart unit tests).
- **Widget behaviour** belongs in `widgets_test.dart` (use `flutter_test` / `WidgetTester`).
- Write tests alongside every new feature or bug fix; do not remove or skip existing tests.
- Keep business logic in controllers so it can be tested without a widget harness.

## Architecture Notes

- `TreeNode<T>` is the core data model. It is generic over the user's payload type `T`.
- `TreeController<T>` drives expansion, selection, filtering, and structural mutations. It exposes a `ValueNotifier`-compatible API so widgets rebuild efficiently.
- `SuperTreeView<T>` renders nodes via a `ListView` (flat-list) for O(visible-nodes) scroll performance. It delegates rendering to user-supplied builder callbacks (`prefixBuilder`, `contentBuilder`, `trailingBuilder`).
- `TreeSearchController<T>` wraps a `TreeController` and adds live fuzzy search/filtering using `FuzzyTreeFilter` and `defaultTreeFuzzyMatcher`.

## Pull Request Guidelines

- Keep changes focused; one logical concern per PR.
- Run `dart analyze` and `flutter test` locally and ensure both pass before opening a PR.
- Update `CHANGELOG.md` for any user-facing change.
- Public API additions must include `///` doc comments.
