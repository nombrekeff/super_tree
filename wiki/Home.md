# Super Tree Wiki

Welcome to the **Super Tree** wiki — a high-performance, fully customizable hierarchical tree view for Flutter.

## What is Super Tree?

`super_tree` lets you build complex tree structures — file explorers, todo lists, permission trees, and more — without writing boilerplate. It is built on a flat-list architecture that keeps large trees smooth even when thousands of nodes are visible.

## Quick Navigation

| Page | Description |
|------|-------------|
| [Getting Started](Getting-Started) | Install the package and build your first tree in minutes |
| [SuperTreeView](SuperTreeView) | Widget API: constructors, builders, and all properties |
| [TreeNode](TreeNode) | The node model: properties, state lifecycle, and helpers |
| [TreeController](TreeController) | Expansion, selection, CRUD, persistence, and more |
| [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) | Styling and interaction behavior configuration |
| [Search & Filtering](Search-and-Filtering) | Fuzzy search, keyword rules, and custom matchers |
| [Prebuilt Widgets](Prebuilt-Widgets) | Drop-in `FileSystemSuperTree` and `TodoListSuperTree` |
| [Drag and Drop](Drag-and-Drop) | Drag-and-drop configuration and drop validation |
| [Keyboard Navigation](Keyboard-Navigation) | Built-in keyboard shortcuts and how to customise them |
| [Async / Lazy Loading](Async-Lazy-Loading) | Load children on demand with error and loading states |

## Key Features at a Glance

- **High Performance** — flat-list architecture for smooth scrolling with large trees
- **Fully Customizable** — control every part of a node row with builder callbacks
- **Desktop & Mobile Ready** — keyboard navigation, right-click / long-press menus, and drag-and-drop
- **State Management** — optional `TreeController` for expansion, selection, filtering, and runtime updates
- **Prebuilt Widgets** — ready-to-use `FileSystemSuperTree` and `TodoListSuperTree`
- **Fuzzy Search** — composable `FuzzyTreeFilter` with keyword rules and custom matcher hooks
- **Lazy Loading** — per-node async loading with loading and error states
- **Testable** — business logic is decoupled from UI

## Package Setup

```yaml
dependencies:
  super_tree: ^0.1.0
```

```dart
import 'package:super_tree/super_tree.dart';
```

## Where to Go Next

New to `super_tree`? Start with **[Getting Started](Getting-Started)**.

Already familiar? Jump directly to the API page you need in the table above.
