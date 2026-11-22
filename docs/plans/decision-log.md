# JSON Better Editor — Decision Log

> Append-only. Every new decision is added as a new row at the end. Requirements live in `requirements-checklist.md`.

## 2026-11-22 — v0.1 review (decisions 1–24)

| # | Topic | Decision |
|---|-------|----------|
| 1 | Platform | macOS only. Windows dropped. |
| 2 | Null type | Added everywhere a type list appears, gray `?` icon. |
| 3 | Mode layout | Side by side 50/50 with splitter; toolbar toggles Text only / Node only / Split. |
| 4 | Drag and drop | Node mode only, one node at a time. |
| 5 | Copy/cut/paste | One node at a time. Text mode = normal text editor. Node mode = shortcuts in 2.7. |
| 6 | Tab key | Indent only (text in Text mode, node in Node mode). Not used to accept autocomplete. |
| 7 | Node indent / de-indent | Tab = become last child of previous sibling; Shift+Tab = become sibling of parent. |
| 8 | Invalid JSON while editing | Node pane shows a blank node; ≤250 ms sync delay OK. Invalid file on open = error dialog, not opened. |
| 9 | Expand/collapse | Expand all, collapse all, expand to depth, collapse siblings. |
| 10 | Child count | `{n}` objects, `[n]` arrays. |
| 11 | Click behavior | Single-click selects and toggles single/multi-line; double-click edits key or value. |
| 12 | Multi-line | Fixed 10 lines. Setting = document default; click toggles per node. |
| 13 | Type change | No automatic conversion; popup with current value for manual edit. |
| 14 | Delete | Confirmation dialog, default Cancel. Undo/redo required. |
| 15 | HTML/Markdown | Syntax-highlighted text editor only, no render, never run scripts. |
| 16 | Base64 images | `data:image/...;base64,` only; 64×64 center-crop thumbnail. |
| 17 | Fonts | System monospace font replaces Plex Mono in both places; fonts not bundled. |
| 18 | Theme | Atom One Light / One Dark; follows OS by default. |
| 19 | Toolbar | Star, Menu and New-dropdown removed. New, Open, Search on left; Language, Theme, Settings on right. |
| 20 | Search | Keys and values, first match, Next/Previous. |
| 21 | Files | Standard File menu; single document per window; multiple instances allowed; test with <5 MB. |
| 22 | Language | Switch button on toolbar, right side. |
| 23 | Word wrap | Text mode lines and long String/Number values in Node mode. |
| 24 | OS integration | Appear in "Open With" and settable as default is enough. |

## 2026-11-22 — v0.2 review (decisions 25–30)

| # | Topic | Decision |
|---|-------|----------|
| 25 | Cmd+V in Node mode | With a node selected (not editing a field), Cmd+V pastes as a child of the selected node. |
| 26 | Undo/redo scope | One shared history across the Text and Node panes. |
| 27 | Layout toggle position | Right group of the toolbar, before the Language switch. |
| 28 | Save formatting | Save reformats (pretty-prints) the JSON. |
| 29 | Missing fonts | If a default font is not installed, use the OS default monospace font. |
| 30 | Language default | Always English. |

## 2026-11-22 — paste shortcuts (decision 31)

| # | Topic | Decision |
|---|-------|----------|
| 31 | Node mode paste shortcuts | Final: Cmd+V = paste as child; Cmd+Shift+V = paste as sibling after; Cmd+Opt+V = paste as sibling before. Cmd+Opt+Shift+V dropped. |
