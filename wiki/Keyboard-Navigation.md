# Keyboard Navigation

`SuperTreeView` registers a set of keyboard shortcuts automatically. When the tree has focus, users can navigate, expand, collapse, and trigger actions entirely from the keyboard — no extra setup required.

---

## Default shortcuts

| Key | Action |
|-----|--------|
| `↓` | Select the next visible node |
| `↑` | Select the previous visible node |
| `→` | Expand the selected node (if collapsed), or move selection to the first child (if already expanded) |
| `←` | Collapse the selected node (if expanded), or move selection to the parent |
| `Home` | Select the first visible node |
| `End` | Select the last visible node |
| `Enter` | Trigger renaming on the selected node (if `namingStrategy` is set), or toggle expansion |
| `Space` | Toggle expansion of the selected node |
| `Shift + ↓` | Extend the selection to the next node (multi-select mode only) |
| `Shift + ↑` | Extend the selection to the previous node (multi-select mode only) |

---

## Requirements

1. The tree widget must receive **keyboard focus**. This happens automatically on tap (the `SuperTreeInteractionSurface` requests focus when the tree area is tapped).
2. At least one node must be selected for directional navigation to move the selection. If nothing is selected, pressing `↓` selects the first node.

---

## Selection mode and keyboard

| `SelectionMode` | Shift+Arrow behaviour |
|----------------|----------------------|
| `none` | Shift+Arrow does nothing |
| `single` | Shift+Arrow moves to next/previous without multi-selecting |
| `multiple` | Shift+Arrow extends the selection range |

---

## Enter vs. Space

| Key | `namingStrategy` | Behaviour |
|-----|-----------------|-----------|
| `Enter` | `none` | Toggle expansion |
| `Enter` | any other | Start renaming the selected node |
| `Space` | any | Toggle expansion (regardless of naming strategy) |

---

## Nested expansion with →

`→` traverses the tree level by level:

1. If the selected node is **collapsed** and has children (or can lazy-load them), expand it.
2. If the selected node is **already expanded**, move the selection to the first visible child.

---

## Parent traversal with ←

`←` walks back up the tree:

1. If the selected node is **expanded**, collapse it.
2. If the selected node is **collapsed**, move the selection to its parent.

---

## Focus programmatically

If you need to focus the tree programmatically (e.g. after a search field is cleared), wrap the tree in a `FocusScope` or call `FocusScope.of(context).requestFocus()`. The internal `FocusNode` is managed automatically by the widget.

---

## See also

- [TreeViewStyle & TreeViewConfig](TreeViewStyle-and-TreeViewConfig) — `selectionMode` and `namingStrategy`
- [TreeController](TreeController) — `selectNext`, `selectPrevious`, `selectFirst`, `selectLast`

- [Drag and Drop](Drag-and-Drop) — mouse-driven tree interaction
