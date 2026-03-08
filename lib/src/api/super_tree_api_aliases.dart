import 'dart:async';

import 'package:super_tree/src/configs/tree_view_logic.dart';
import 'package:super_tree/src/configs/tree_view_style.dart';
import 'package:super_tree/src/controllers/tree_controller.dart';
import 'package:super_tree/src/controllers/tree_events.dart';
import 'package:super_tree/src/controllers/tree_search_controller.dart';
import 'package:super_tree/src/models/tree_node.dart';

/// Preferred user-facing alias for [TreeNode].
typedef SuperTreeNode<T> = TreeNode<T>;

/// Preferred user-facing alias for [TreeController].
typedef SuperTreeController<T> = TreeController<T>;

/// Preferred user-facing alias for [TreeSearchController].
typedef SuperTreeSearchController<T> = TreeSearchController<T>;

/// Preferred user-facing alias for [TreeLoadChildrenCallback].
typedef SuperTreeLoadChildrenCallback<T> = TreeLoadChildrenCallback<T>;

/// Preferred user-facing alias for [TreeNodeAsyncState].
typedef SuperTreeNodeAsyncState = TreeNodeAsyncState;

/// Preferred user-facing alias for [TreeIntegrityIssue].
typedef SuperTreeIntegrityIssue = TreeIntegrityIssue;

/// Preferred user-facing alias for [TreeIntegrityIssueType].
typedef SuperTreeIntegrityIssueType = TreeIntegrityIssueType;

/// Preferred user-facing alias for [TreeEvent].
typedef SuperTreeEvent<T> = TreeEvent<T>;

/// Preferred user-facing alias for [TreeNodeAddedEvent].
typedef SuperTreeNodeAddedEvent<T> = TreeNodeAddedEvent<T>;

/// Preferred user-facing alias for [TreeNodeRemovedEvent].
typedef SuperTreeNodeRemovedEvent<T> = TreeNodeRemovedEvent<T>;

/// Preferred user-facing alias for [TreeNodeMovedEvent].
typedef SuperTreeNodeMovedEvent<T> = TreeNodeMovedEvent<T>;

/// Preferred user-facing alias for [TreeNodeRenamedEvent].
typedef SuperTreeNodeRenamedEvent<T> = TreeNodeRenamedEvent<T>;

/// Preferred user-facing alias for [TreeViewConfig].
typedef SuperTreeViewConfig<T> = TreeViewConfig<T>;

/// Preferred user-facing alias for [TreeViewStyle].
typedef SuperTreeViewStyle = TreeViewStyle;

/// Preferred user-facing alias for [ExpansionTrigger].
typedef SuperTreeExpansionTrigger = ExpansionTrigger;

/// Preferred user-facing alias for [SelectionMode].
typedef SuperTreeSelectionMode = SelectionMode;

/// Preferred user-facing alias for [TreeNamingStrategy].
typedef SuperTreeNamingStrategy = TreeNamingStrategy;

/// Preferred user-facing alias for [StreamSubscription].
typedef SuperTreeEventSubscription<T> = StreamSubscription<SuperTreeEvent<T>>;
