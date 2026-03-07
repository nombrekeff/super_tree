/// Signature for providing a string label from a data object of type [T].
typedef TreeLabelProvider<T> = String Function(T data);

/// Represents a single node in the [SuperTreeView].
///
/// The generic type [T] allows the node to hold custom business data.
class TreeNode<T> {
  /// Unique identifier for this node. Useful for expanding/collapsing by ID,
  /// preserving state, and finding nodes efficiently.
  String id;

  /// Business logic or data associated with this node.
  final T data;

  /// Private children list to allow interception by the controller.
  final List<TreeNode<T>> _children;

  /// Whether this node is currently expanded to show its children.
  bool isExpanded;

  /// Whether this node is currently selected.
  bool isSelected;

  /// Whether this node can lazily load children on first expansion.
  ///
  /// When true, UI may show an expansion affordance even if [children] is empty.
  bool canLoadChildren;

  /// Reference to the parent node. Null if this is a root node.
  TreeNode<T>? parent;

  /// Whether this node is a temporary "new" node being created.
  bool isNew;

  static int _idCounter = 0;

  /// Creates a new [TreeNode] with a required [data] and optional [id].
  ///
  /// The [children] list, [isExpanded], and [isSelected] flags are optional.
  TreeNode({
    String? id,
    required this.data,
    List<TreeNode<T>>? children,
    this.isExpanded = false,
    this.isSelected = false,
    this.canLoadChildren = false,
    this.isNew = false,
    this.parent,
  }) : id = id ?? 'node_${++_idCounter}',
       _children = children ?? <TreeNode<T>>[] {
    _bindChildren();
  }

  /// Iterates over initial children and sets this node as their parent.
  void _bindChildren() {
    for (var child in _children) {
      child.parent = this;
    }
  }

  /// Returns the unmodifiable list of children.
  /// To modify children, use the [TreeController] to guarantee state updates.
  List<TreeNode<T>> get children => List<TreeNode<T>>.unmodifiable(_children);

  /// Helper getter to compute the node's depth in the tree.
  /// A root node has a depth of 0.
  int get depth {
    int computedDepth = 0;
    TreeNode<T>? currentParent = parent;
    while (currentParent != null) {
      computedDepth++;
      currentParent = currentParent.parent;
    }
    return computedDepth;
  }

  /// Returns true if the node has any children.
  bool get hasChildren => _children.isNotEmpty;

  /// Returns true if this is a root node (i.e. it has no parent).
  bool get isRoot => parent == null;

  /// Returns true if this node has no children.
  bool get isLeaf => _children.isEmpty;

  /// Deep copies this node and optionally applies new properties.
  TreeNode<T> copyWith({
    String? id,
    T? data,
    List<TreeNode<T>>? children,
    bool? isExpanded,
    bool? isSelected,
    bool? canLoadChildren,
    bool? isNew,
    TreeNode<T>? parent,
  }) {
    return TreeNode<T>(
      id: id ?? this.id,
      data: data ?? this.data,
      children: children ?? _children.map((c) => c.copyWith()).toList(),
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      canLoadChildren: canLoadChildren ?? this.canLoadChildren,
      isNew: isNew ?? this.isNew,
      parent: parent ?? this.parent,
    );
  }

  /// Internal method meant to be called by the TreeController to add a child.
  void internalAddChild(TreeNode<T> child) {
    if (_children.any((TreeNode<T> existing) => existing.id == child.id)) {
      assert(false, 'Duplicate sibling ID detected: "${child.id}".');
      return;
    }

    child.parent = this;
    _children.add(child);
  }

  /// Internal method meant to be called by the TreeController to remove a child.
  void internalRemoveChild(TreeNode<T> child) {
    _children.remove(child);
    child.parent = null;
  }

  /// Internal method meant to be called by the TreeController to insert a child.
  void internalInsertChild(int index, TreeNode<T> child) {
    if (_children.any((TreeNode<T> existing) => existing.id == child.id)) {
      assert(false, 'Duplicate sibling ID detected: "${child.id}".');
      return;
    }

    child.parent = this;
    _children.insert(index, child);
  }

  /// Internal method meant to be called by the TreeController to sort children.
  void internalSortChildren(
    int Function(TreeNode<T> a, TreeNode<T> b) comparator, {
    bool recursive = false,
  }) {
    _children.sort(comparator);
    if (recursive) {
      for (var child in _children) {
        child.internalSortChildren(comparator, recursive: true);
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeNode<T> && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
