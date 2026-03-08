import 'package:flutter/material.dart';
import 'package:super_tree/src/configs/tree_drag_and_drop_config.dart';

/// Configuration for the visual appearance of the [SuperTreeView].
class TreeViewStyle {
  /// Padding applied to each node row.
  final EdgeInsetsGeometry padding;

  /// Amount of horizontal space added for each level of depth.
  final double indentAmount;

  /// Text style for the node labels.
  final TextStyle? textStyle;

  /// Background color of a node when idle.
  final Color idleColor;

  /// Background color of a node when hovered.
  final Color hoverColor;

  /// Background color of a node when selected.
  final Color selectedColor;

  /// Animation duration for expand/collapse (e.g. caret rotation).
  final Duration expandAnimationDuration;

  /// TextStyle for the node label.
  final TextStyle? labelStyle;

  /// Visual style options specific to drag-and-drop interactions.
  final TreeDragAndDropStyle dragAndDrop;

  /// Creates a [TreeViewStyle] with sensible defaults.
  const TreeViewStyle({
    this.padding = const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
    this.indentAmount = 24.0,
    this.textStyle,
    this.idleColor = Colors.transparent,
    this.hoverColor = const Color(0x1A000000), // Light grey transparent
    this.selectedColor = const Color(0x33000000), // Darker transparent
    this.expandAnimationDuration = const Duration(milliseconds: 200),
    this.labelStyle,
    this.dragAndDrop = const TreeDragAndDropStyle(),
  });

  /// Returns a copy of this style with the given fields replaced.
  TreeViewStyle copyWith({
    EdgeInsetsGeometry? padding,
    double? indentAmount,
    TextStyle? textStyle,
    Color? idleColor,
    Color? hoverColor,
    Color? selectedColor,
    Duration? expandAnimationDuration,
    TextStyle? labelStyle,
    TreeDragAndDropStyle? dragAndDrop,
  }) {
    return TreeViewStyle(
      padding: padding ?? this.padding,
      indentAmount: indentAmount ?? this.indentAmount,
      textStyle: textStyle ?? this.textStyle,
      idleColor: idleColor ?? this.idleColor,
      hoverColor: hoverColor ?? this.hoverColor,
      selectedColor: selectedColor ?? this.selectedColor,
      expandAnimationDuration: expandAnimationDuration ?? this.expandAnimationDuration,
      labelStyle: labelStyle ?? this.labelStyle,
      dragAndDrop: dragAndDrop ?? this.dragAndDrop,
    );
  }
}
