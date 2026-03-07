import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

/// Shared search lifecycle helper for example screens.
class ExampleTreeSearchLogic<T> {
  ExampleTreeSearchLogic({
    required this.searchController,
  });

  final TreeSearchController<T> searchController;

  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  bool isSearchVisible = false;

  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }

  void open({required VoidCallback refresh}) {
    if (!isSearchVisible) {
      isSearchVisible = true;
      refresh();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!focusNode.canRequestFocus) {
        return;
      }
      focusNode.requestFocus();
      textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textController.text.length,
      );
    });
  }

  void close({required VoidCallback refresh}) {
    textController.clear();
    searchController.clearSearch();
    if (isSearchVisible) {
      isSearchVisible = false;
      refresh();
    }
  }

  void handleChanged(String value) {
    if (value.trim().isEmpty) {
      searchController.clearSearch();
      return;
    }
    searchController.search(value);
  }
}
