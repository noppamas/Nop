# JSON Better Editor — Development Phases

> Rough task breakdown by phase, agreed with Jedt on 2026-11-22.
> Section numbers (e.g. §1.3) refer to [`requirements-checklist.md`](requirements-checklist.md). Phase decisions are logged in [`decision-log.md`](decision-log.md).
> Platform: Flutter desktop, macOS only.

Each phase ends with an app that builds and runs on macOS. A phase starts only after the previous one works.

---

## Phase 1 — Bootstrap

Goal: the application is up and running on macOS with very basic features, and the foundations later phases build on.

- [ ] Create the Flutter macOS project, folder structure, lint and test setup.
- [ ] Basic Material 3 theme (§3.6). Full One Light / One Dark comes in Phase 4.
- [ ] i18n scaffolding with English as the default language (§3.7). Thai strings and the switch come in Phase 4.
- [ ] Main window and toolbar skeleton (§3.2): New, Open, Search, Layout toggles, Language, Theme, Settings. Buttons can be placeholders.
- [ ] Shared JSON document model used by both Text and Node panes (§1.2). Covers all six types, including Null.
- [ ] Open, Save and Save As for `.json` files (§3.4).
- [ ] Invalid JSON on open: error dialog with position, file not opened (§1.2).
- [ ] Plain text view of the opened document (no highlighting yet).
- [ ] CI build and a smoke test that the app launches on macOS.

**Done when:** you can open a valid `.json` file, see its text, save it, and an invalid file shows an error dialog.

---

## Phase 2 — Text mode complete (tech base)

Goal: every Text-mode feature and the file/editor basics, on top of the Phase 1 base.

- [ ] Syntax highlighting, line numbers, bracket and quote matching (§1.1).
- [ ] Fold/unfold objects and arrays from the gutter (§1.1).
- [ ] Key autocomplete from existing keys, accepted with Enter/Return (§1.3).
- [ ] Tab / Shift+Tab indent and de-indent text (§1.4).
- [ ] Copy, cut and paste with normal text-editor behavior (§1.4).
- [ ] Word wrap toggle for Text mode (§1.5).
- [ ] Search keys and values with Next / Previous (§3.3), Text mode side.
- [ ] Undo / redo in Text mode (§3.5).
- [ ] Save reformats (pretty-prints) the JSON (§3.4).
- [ ] Standard File menu: New, Open, Save, Save As, Close; one document per window, multiple instances (§3.4).
- [ ] Register as a `.json` handler in "Open With" (§3.8).
- [ ] Check performance with files under 5 MB (§3.4).

**Done when:** the app works as a complete JSON text editor on its own.

---

## Phase 3 — Node Visualization

Goal: introduce the Node pane, and with it the split view and two-way sync.

### 3a. Tree view
- [ ] Tree with indentation and guide lines (§2.1).
- [ ] Row layout, type icons and colors, `{n}` / `[n]` badges, delete icon (§2.2).
- [ ] Expand all, collapse all, expand to depth, collapse siblings (§2.1).
- [ ] Select on single-click; single/multi-line value toggle, 10-line limit (§2.3).
- [ ] Word wrap for long String/Number values (§2.2).

### 3b. Editing
- [ ] Double-click to edit key and value (§2.4).
- [ ] Type dropdown with manual-conversion popup (§2.4).
- [ ] Delete with confirmation, default Cancel (§2.4).
- [ ] `+ ADD` inline new-node row (§2.5).

### 3c. Moving and clipboard
- [ ] Drag and drop one node with an insertion line (§2.6).
- [ ] Tab / Shift+Tab to indent and de-indent nodes (§2.6).
- [ ] Copy/cut one node; Cmd+V child, Cmd+Shift+V sibling after, Cmd+Opt+V sibling before; context menu (§2.7).

### 3d. Split view and sync
- [ ] Side-by-side 50/50 layout with splitter; Text only / Node only / Split toggles (§3.1).
- [ ] Two-way content sync, scroll percentage and selection sync (§3.1).
- [ ] Blank node while Text has invalid JSON, sync delay ≤250 ms (§3.1).
- [ ] One shared undo history across both panes (§3.5).
- [ ] Search works in Node mode too (§3.3).

### 3e. Rich value previews
- [ ] Detect `data:image/...;base64,` values, 64×64 center-crop thumbnail, full-image popup (§2.8).
- [ ] Detect HTML/Markdown, edit in a syntax-highlighted popup editor, no rendering or scripts (§2.8).

**Done when:** both panes work side by side and every edit in one appears in the other.

---

## Phase 4 — Settings

Goal: the Settings screen and everything it controls.

- [ ] Settings screen from the gear icon (§3.9).
- [ ] Atom One Light / One Dark themes, follow macOS appearance by default, toolbar toggle overrides (§3.9).
- [ ] Default fonts: IBM Plex Sans (UI), IBM Plex Mono (keys/types, Text mode), IBM Plex Sans Thai Looped (values); not bundled (§3.9).
- [ ] Choose a system monospace font, replacing Plex Mono in Text mode and Node keys/types (§3.9).
- [ ] Fallback to the macOS default monospace font when a font is missing (§3.9).
- [ ] Document-wide default for single-line or multi-line values (§3.9, §2.3).
- [ ] Full Thai translation and the toolbar language switch; English on first launch (§3.7).

**Done when:** every setting in §3.9 works and persists between launches.
