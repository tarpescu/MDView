# MDView User Guide

This guide covers everyday use of **MDView**, a lightweight native macOS Markdown reader and editor: workspace modes, tabs and windows, links, session restore, the outline, and customization.

---

## 📖 Table of Contents

1. [Workspace Modes](#1-workspace-modes)
2. [Opening Files & Following Links](#2-opening-files--following-links)
3. [Tabs & Windows](#3-tabs--windows)
4. [Saving, Unsaved Changes & Session Restore](#4-saving-unsaved-changes--session-restore)
5. [Outline Sidebar](#5-outline-sidebar)
6. [Status Bar Statistics](#6-status-bar-statistics)
7. [Zoom](#7-zoom)
8. [Themes & Appearance](#8-themes--appearance)
9. [Printing & Exporting to PDF](#9-printing--exporting-to-pdf)
10. [Settings Reference](#10-settings-reference)

---

## 1. Workspace Modes

Each tab remembers its own mode. Switch with the segmented control in the toolbar or with the shortcuts below.

```
┌──────────────────────────────────────────────────────────────┐
│   [ Viewer  ⌘1 ]   │   [ Split  ⌘2 ]   │   [ Editor  ⌘3 ]    │
└──────────────────────────────────────────────────────────────┘
```

### Viewer (`⌘1`)

For reading documentation, READMEs and notes.

- **GitHub Flavored Markdown** — tables, task lists (`- [x]`), strikethrough (`~~text~~`), blockquotes, nested lists and fenced code blocks.
- **Local images** — relative image paths such as `![Diagram](assets/diagram.png)` are resolved against the document's folder and shown at their natural size (shrunk to fit). A missing image shows a small placeholder with its file name.
- **Selectable text** — rendered text can be selected and copied.
- **Large documents** — the document is split at headings and rendered lazily, section by section.

### Split (`⌘2`)

Source editor on the left, live preview on the right. The preview updates as you type; the divider can be dragged.

### Editor (`⌘3`)

A monospaced AppKit `NSTextView` with Markdown syntax highlighting (headings, bold, italic, inline code, links). Only the paragraph you are editing is re-highlighted, so typing stays responsive in long files.

**Editing shortcuts** (active while the editor has keyboard focus):

| Shortcut | Effect |
| :--- | :--- |
| <kbd>⌘</kbd> <kbd>B</kbd> | Wraps the selection in `**…**`, or inserts `****` with the cursor in the middle |
| <kbd>⌘</kbd> <kbd>I</kbd> | Wraps the selection in `*…*`, or inserts `**` with the cursor in the middle |
| <kbd>⌘</kbd> <kbd>K</kbd> | Turns the selection into `[selection](url)` with `url` selected, ready to type over |
| <kbd>⌘</kbd> <kbd>F</kbd> | Opens the Find bar (<kbd>⌘</kbd> <kbd>G</kbd> / <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>G</kbd> for next / previous, Replace is available from the bar) |
| <kbd>⌘</kbd> <kbd>Z</kbd> | Undo — formatting shortcuts are fully undoable |

Smart quotes, smart dashes and autocorrect are disabled so Markdown syntax is never rewritten behind your back.

---

## 2. Opening Files & Following Links

### From Finder

When MDView is installed as an app bundle (see the README's *Build a real `.app` bundle*), it registers for `.md`, `.markdown`, `.mdown`, `.mkdn` and plain-text files:

- **Set as default** — *right-click a file* → **Get Info** → **Open with: MDView** → **Change All…**
- **Double-click** a file to open it as a tab in the frontmost MDView window (a new window is created if none is open). If that window only holds an empty *Untitled* tab, the file replaces it.
- **Drop files on the Dock icon** to open them the same way.

### Open dialog (`⌘O`)

Shows the standard open panel as a sheet. Select several files with <kbd>⇧</kbd> or <kbd>⌘</kbd> to open them all as tabs. A file that is already open is focused instead of being opened twice.

### Drag and drop

- **Onto a window** — drop Markdown or text files from Finder anywhere on the tab bar or the preview to open them as tabs.
- **Onto the editor** — dropping Markdown files opens them as tabs; dropping **images** inserts a reference at the drop point, using a path relative to the document when possible:

  ```markdown
  ![diagram](assets/diagram.png)
  ```

  Spaces and other special characters in the path are percent-encoded so the link stays valid.

### Relative links between documents

Links are resolved relative to the folder of the current document:

```markdown
[Developer Guide](./ARCHITECTURE.md)
[Contributing](../CONTRIBUTING.md)
[Changelog](CHANGELOG)        <!-- no extension: CHANGELOG.md is tried first -->
```

| Link target | What happens |
| :--- | :--- |
| Markdown file (`.md`, `.markdown`, `.mdown`, `.mkdn`, `.mkd`) | Opens as a tab in the current window, or focuses it if already open |
| Other local file or folder (`.pdf`, `.png`, `.csv`, …) | Opens in its default app (folders open in Finder) |
| `http`, `https`, `mailto`, `tel` and other URL schemes | Handed to macOS (your default browser, mail client, …) |
| Missing file | An alert shows the full path that was looked up |

> Relative links need a saved document — in an *Untitled* tab there is no folder to resolve against, and MDView tells you so.

### Anchors inside a document

```markdown
[Jump to the overview](#architecture-overview)
```

Clicking an anchor scrolls the preview to the matching heading. Anchors follow GitHub's rules: lowercase, punctuation and emoji removed, spaces become `-` — so `## 3. Tab & Window` is `#3-tab--window`. Repeated headings get `-1`, `-2`, … suffixes, exactly like on GitHub.

---

## 3. Tabs & Windows

```
┌──────────────────────────────────────────────────────────────────────────┐
│ ( 📄 README  ×)  ( 📄 ARCHITECTURE • )  ( 📄 USAGE )                  [+] │
└──────────────────────────────────────────────────────────────────────────┘
```

- **Active tab** — raised pill with a border and soft shadow.
- **Titles** — the file name without its extension; hover a tab to see the full path.
- **Close buttons** — visible on the active tab and on the tab under the pointer.
- **Unsaved dot** — a small dot marks tabs with unsaved changes.

### Creating and closing tabs

| Action | How |
| :--- | :--- |
| New blank tab | **+** button or <kbd>⌘</kbd> <kbd>T</kbd> |
| Close active tab | <kbd>⌘</kbd> <kbd>W</kbd> |
| Close a specific tab | Its **×** button, or click it with the **middle mouse button** |
| Close all other tabs | Right-click a tab → **Close Other Tabs** |
| Reveal file / copy its path | Right-click a tab → **Reveal in Finder** / **Copy Path** |

Closing the last tab of a window closes the window. Closing the last tab of the **whole app** quits MDView and clears the saved session, so the next launch starts fresh.

### Switching tabs

- Next tab: <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>]</kbd>
- Previous tab: <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>[</kbd>

Navigation wraps around from the last tab to the first.

### Multiple windows (`⌘N`)

Every window has its own set of tabs. Menu commands and shortcuts always act on the frontmost window; files opened from Finder go to the window you used last.

---

## 4. Saving, Unsaved Changes & Session Restore

### Saving

- <kbd>⌘</kbd> <kbd>S</kbd> writes the file in place (UTF-8). For an *Untitled* tab it behaves like **Save As…**.
- <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>S</kbd> saves a copy under a new name; the tab then points to the new file.

Files in other encodings (UTF-16, Latin-1, …) are opened correctly and saved back as UTF-8. If a file cannot be read at all, **Save** always asks for a new location so the original is never overwritten with an empty document.

### When you close or quit with unsaved changes

- **Closing a tab** asks *Save*, *Cancel* or *Don't Save*. Choosing *Save* on an *Untitled* tab shows the save panel and closes the tab once the file is written.
- **Closing a window** (red button or <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>W</kbd>) asks the same question for that window's unsaved tabs (**Save All**, **Cancel**, **Discard Changes** when there are several).
- **Quitting** (<kbd>⌘</kbd> <kbd>Q</kbd>) does the same for every window.

Untitled drafts are not counted on quit (or when closing the last window) while session restore is on, because they are kept in the session.

### Session restore

With **Settings → Startup → Restore windows and tabs on reopen** enabled (the default), MDView remembers:

- every open window and its tabs, in order, and which tab was selected;
- each tab's mode (Viewer / Split / Editor);
- the full text of **Untitled drafts**, so they survive quitting — they are still marked as unsaved and will ask before being closed.

Files that were moved or deleted since the last launch are skipped. Turning the setting off deletes the stored session immediately. The session lives in `~/Library/Application Support/MDView/session.json`.

---

## 5. Outline Sidebar

Toggle it with the sidebar button at the left of the toolbar; its visibility is remembered across tabs and launches.

- Lists `#` through `######` headings, indented by level. Lines inside fenced code blocks (for example `# install` in a shell snippet) are ignored.
- Click an entry to jump there — the preview scrolls to the section, and in Split / Editor mode the cursor moves to the heading line.
- The line number of each heading is shown on the right; hover an entry to see a long title in full.

---

## 6. Status Bar Statistics

```
┌──────────────────────────────────────────────────────────────────────────┐
│  3,420 words   21,480 characters   512 lines                 ⏱ 18 min read │
└──────────────────────────────────────────────────────────────────────────┘
```

- **Words** — whitespace-separated tokens (Markdown symbols such as `#` or `-` count when they stand alone).
- **Characters** — user-perceived characters (an emoji counts as one).
- **Lines** — line breaks + 1.
- **Reading time** — words ÷ 200 words per minute, rounded up.

Statistics are recomputed 120 ms after you stop typing, on a background thread, so they never slow down editing.

---

## 7. Zoom

| Shortcut | Effect |
| :--- | :--- |
| <kbd>⌘</kbd> <kbd>+</kbd> or <kbd>⌘</kbd> <kbd>=</kbd> | Zoom in by 10 % |
| <kbd>⌘</kbd> <kbd>-</kbd> | Zoom out by 10 % |
| <kbd>⌘</kbd> <kbd>0</kbd> | Back to 100 % |

The range is **70 %–250 %**. Zoom applies to both the preview and the editor and is shared by all windows; the default can also be set with the slider in Settings.

---

## 8. Themes & Appearance

Choose from the toolbar's appearance menu or in Settings (<kbd>⌘</kbd> <kbd>,</kbd>):

1. **System** (default) — follows macOS Light/Dark mode automatically.
2. **Light** — always light.
3. **Dark** — always dark.
4. **Sepia** — warm paper background with brown ink, for long reading sessions.

---

## 9. Printing & Exporting to PDF

- **Print** (<kbd>⌘</kbd> <kbd>P</kbd>) — opens the standard print dialog (printer, page range, copies). Output uses the current zoom level.
- **Export as PDF** (<kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>E</kbd>) — asks for a location and writes a vector PDF at 100 % scale; text stays selectable and searchable.

Both use your default paper size with 48 pt margins and always render dark text on white paper, whatever theme the app is using. Code blocks wrap instead of scrolling, and local images and tables are included.

---

## 10. Settings Reference

| Setting | Default | Effect |
| :--- | :--- | :--- |
| Restore windows and tabs on reopen | On | See [Session restore](#session-restore) |
| Appearance | System | Theme for every window |
| Default Zoom | 100 % | Same value as the View ▸ Zoom commands |
