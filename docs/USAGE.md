# MDView User Guide

Welcome to the comprehensive user guide for **MDView**, a lightweight, high-performance native macOS Markdown reader and editor. This guide covers daily workflows, workspace modes, tab and window management, local file navigation, and customization options.

---

## 📖 Table of Contents

1. [Workspace Modes](#1-workspace-modes)
   - [Viewer Mode (⌘1)](#viewer-mode-1)
   - [Split Mode (⌘2)](#split-mode-2)
   - [Editor Mode (⌘3)](#editor-mode-3)
2. [File Ingestion & Navigation](#2-file-ingestion--navigation)
   - [Opening Files via Finder](#opening-files-via-finder)
   - [Open File Dialog (⌘O)](#open-file-dialog-o)
   - [Drag-and-Drop Ingestion](#drag-and-drop-ingestion)
   - [Smart Relative Link Resolution](#smart-relative-link-resolution)
   - [Intra-Document Anchors & Headings](#intra-document-anchors--headings)
3. [Safari-Style Tab & Window Management](#3-safari-style-tab--window-management)
   - [Pill Tab Bar Overview](#pill-tab-bar-overview)
   - [Tab Creation and Closing](#tab-creation-and-closing)
   - [Tab Navigation & Shortcuts](#tab-navigation--shortcuts)
   - [Unsaved Changes Indicators](#unsaved-changes-indicators)
   - [Multi-Window Workspaces (⌘N)](#multi-window-workspaces-n)
4. [Table of Contents Sidebar](#4-table-of-contents-sidebar)
5. [Real-Time Document Telemetry](#5-real-time-document-telemetry)
6. [Typography Zoom & Scaling](#6-typography-zoom--scaling)
7. [Themes & Appearance Modes](#7-themes--appearance-modes)
8. [Printing & Exporting to PDF](#8-printing--exporting-to-pdf)

---

## 1. Workspace Modes

MDView is designed around a **Tri-Modal Workspace** that lets you adapt the interface to whether you are reading, authoring, or editing code documentation. Switch between modes instantly using the segmented toolbar control or dedicated shortcuts:

```
┌────────────────────────────────────────────────────────┐
│  [  Viewer (⌘1)  ]  |  [  Split (⌘2)  ]  |  [  Editor (⌘3)  ]  │
└────────────────────────────────────────────────────────┘
```

### Viewer Mode (`⌘1`)

**Ideal for**: Reading documentation, reviewing proposals, checking README files, and distraction-free reference.

- **Human Interface Guidelines Styling**: Renders Markdown with native macOS typography, proportional headings, legible body text, and styled code blocks.
- **GitHub Flavored Markdown (GFM)**: Supports tables, task lists (`- [x]`), blockquotes, strikethrough (`~~text~~`), nested bullet lists, and fenced code blocks.
- **Local Asset Loading**: Resolves and renders local relative image paths (e.g. `![Diagram](assets/diagram.png)`) directly against the document's directory.
- **Interactive Links**: External web links open in Safari; local Markdown links open as new tabs within MDView.
- **Selectable & Searchable**: Native AppKit text rendering allows you to select, copy, and search formatted text effortlessly.

### Split Mode (`⌘2`)

**Ideal for**: Authoring articles, taking structured notes, and writing technical documentation with continuous visual feedback.

- **Synchronized Work Area**: Places the high-performance AppKit source editor on the left and the live rendered Markdown preview on the right.
- **Real-Time Render Pipeline**: As you type on the left, the preview updates dynamically.
- **Debounced Background Sync**: Parsing and outline updates run asynchronously off the main thread, maintaining fluid 120 FPS cursor movement and zero typing latency.

### Editor Mode (`⌘3`)

**Ideal for**: High-speed drafting, code block formatting, large document edits, and raw Markdown manipulation.

- **Monospaced Native Buffer**: Powered by a custom AppKit `NSTextView` configured with system monospaced typography.
- **$O(1)$ Paragraph-Bounded Syntax Highlighting**: Unlike web-based editors that re-parse the entire document upon every keystroke, MDView highlights only the paragraph currently being modified. Large documents (5,000–10,000+ lines) edit with zero lag.
- **Formatting Accelerators**:
  - <kbd>⌘</kbd> <kbd>B</kbd>: Wrap selected text in bold (`**selection**`) or insert `****` at cursor.
  - <kbd>⌘</kbd> <kbd>I</kbd>: Wrap selected text in italics (`*selection*`) or insert `**` at cursor.
  - <kbd>⌘</kbd> <kbd>K</kbd>: Convert selection into a Markdown link (`[selection](url)`) and auto-select `url` for typing.

---

## 2. File Ingestion & Navigation

MDView provides seamless integration with the macOS filesystem.

### Opening Files via Finder

- **Default Application**: Configure MDView as the default handler for `.md`, `.markdown`, `.mdown`, and `.txt` files in macOS Finder (*Right-click file* → *Get Info* → *Open with: MDView* → *Change All*).
- **Double-Clicking in Finder**: Double-clicking any supported file opens it as a tab in your frontmost active MDView window. If no window is open, a new window launches automatically.
- **Dock Icon Drop**: Dragging files onto the MDView Dock icon queues them to open in the key window.

### Open File Dialog (`⌘O`)

Press <kbd>⌘</kbd> <kbd>O</kbd> at any time to present the native macOS file picker modal sheet.
- **Multi-Selection**: Hold <kbd>Shift</kbd> or <kbd>⌘</kbd> to select multiple `.md` files at once. All selected files open simultaneously as distinct tabs in the current window.
- **Content Filtering**: Filters automatically to supported plain text and Markdown document types.

### Drag-and-Drop Ingestion

MDView supports macOS drag-and-drop gestures:
1. **Drag from Finder into Tab Bar**: Drag one or more Markdown files directly from Finder onto the Safari tab bar to append them as new tabs.
2. **Drag from Finder into Editor**: Dragging image files into the raw editor inserts corresponding relative Markdown image references.

### Smart Relative Link Resolution

A common frustration with Markdown viewers is broken local links when navigating multi-file documentation sets (such as wikis, Git repositories, or project docs). MDView solves this natively:

1. **Automatic Directory Context**: When viewing a document located at `/Projects/Docs/index.md`, MDView establishes `/Projects/Docs/` as the document's base URL.
2. **Relative File Paths**: Clicking a relative link such as:
   ```markdown
   [Developer Guide](./ARCHITECTURE.md)
   [Contributing Guidelines](../CONTRIBUTING.md)
   [Changelog](CHANGELOG)
   ```
   automatically resolves the path relative to the active document.
3. **In-App Tab Opening**: If the target is a Markdown file, MDView opens it directly as a new tab in the active window.
4. **Duplicate Tab Reuse**: If the target document is already open in another tab in the window, MDView focuses that tab rather than creating a duplicate.
5. **Non-Markdown Files**: If the target link points to an external file (e.g. `spec.pdf` or `dataset.csv`), MDView delegates opening to the system via `NSWorkspace`.
6. **External Web URLs**: Links beginning with `http://` or `https://` hand off directly to your default macOS browser (e.g., Safari).

### Intra-Document Anchors & Headings

When a document links to an internal section using a heading hash anchor:
```markdown
[Jump to Architecture](#architecture-overview)
```
MDView intercepts the click, locates the matching heading in the parsed document tree, and animates a smooth scroll directly to that section in the viewport.

---

## 3. Safari-Style Tab & Window Management

MDView features a custom pill-shaped tab bar modeled after the modern macOS Safari design.

```
┌────────────────────────────────────────────────────────────────────────┐
│ (  📄 README.md  )  (  📄 ARCHITECTURE.md •  )  (  📄 USAGE.md [×]  )  [+]│
└────────────────────────────────────────────────────────────────────────┘
```

### Pill Tab Bar Overview

- **Active Tab Pill**: The focused document is styled as an elevated white/translucent capsule with a subtle border and shadow, clearly distinguishing it from background tabs.
- **Document Icon & Truncation**: Displays the native document icon and file title, cleanly truncating long titles with an ellipsis.
- **Hover Reveal**: Close buttons (<kbd>×</kbd>) remain hidden on inactive tabs until you hover over them, keeping the interface uncluttered.

### Tab Creation and Closing

- **New Blank Tab**: Click the **`+`** button at the right edge of the tab strip or press <kbd>⌘</kbd> <kbd>T</kbd>.
- **Close Active Tab**: Press <kbd>⌘</kbd> <kbd>W</kbd>.
- **Close Specific Tab**: Hover over any tab pill and click the <kbd>×</kbd> button.
- **Middle-Click Closure**: If you use a mouse with a clickable scroll wheel or trackpad three-finger click simulation, clicking any tab pill with the **middle mouse button** closes that tab immediately.
- **Last Tab Behavior**: Closing the final remaining tab in a window automatically closes the host window.

### Tab Navigation & Shortcuts

Cycle through your open documents without touching the mouse:
- **Next Tab**: Press <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>]</kbd>
- **Previous Tab**: Press <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>[</kbd>

Navigation wraps around seamlessly from the last tab to the first.

### Unsaved Changes Indicators

When you modify a document, MDView displays a subtle circular dot indicator inside the tab pill:
- The dot persists until you save the document (<kbd>⌘</kbd> <kbd>S</kbd>).
- If you attempt to close an unsaved tab or window, MDView prompts you to save your changes or discard them.

### Multi-Window Workspaces (`⌘N`)

MDView supports an independent multi-window architecture:
- Press <kbd>⌘</kbd> <kbd>N</kbd> to spawn a completely separate window instance.
- Each window manages its own independent array of tabs and selected document state.
- Keyboard shortcuts and menu operations automatically target the frontmost (key) window.

---

## 4. Table of Contents Sidebar

Click the sidebar toggle button in the toolbar (<kbd>sidebar.left</kbd>) to reveal the **Document Outline**:

- **Hierarchical Outline**: Automatically extracts `# H1`, `## H2`, `### H3`, `#### H4`, `##### H5`, and `###### H6` headings in real time.
- **Visual Indentation**: Subheadings are indented proportionally to their depth level.
- **Jump Navigation**: Click any entry in the outline to instantly jump to that heading in either Viewer or Editor mode.
- **Selection Highlight**: The sidebar highlights the heading corresponding to your current reading position.

---

## 5. Real-Time Document Telemetry

Located at the bottom of each tab, the subtle status bar provides live document statistics:

```
┌────────────────────────────────────────────────────────────────────────┐
│  3,420 words  ·  21,480 characters  ·  ~14 min read                    │
└────────────────────────────────────────────────────────────────────────┘
```

- **Word Count**: Accurately counts whitespace-delimited words while excluding raw markdown markup tokens.
- **Character Count**: Full unicode-compliant character count.
- **Reading Time**: Calculated assuming an average adult reading speed of 225 words per minute.
- **Performance Guarantee**: Telemetry calculations are debounced by 120ms and processed via asynchronous background tasks, ensuring that rapid typing remains buttery smooth at 120Hz.

---

## 6. Typography Zoom & Scaling

MDView allows you to scale the entire reading and editing typography dynamically:

- **Zoom In**: Press <kbd>⌘</kbd> <kbd>+</kbd> (or <kbd>⌘</kbd> <kbd>=</kbd>) to increase font size in 10% increments.
- **Zoom Out**: Press <kbd>⌘</kbd> <kbd>-</kbd> to decrease font size in 10% increments.
- **Actual Size**: Press <kbd>⌘</kbd> <kbd>0</kbd> to reset zoom back to 100%.

Zoom scales proportional sizing across headings, body text, monospaced code blocks, and the AppKit source editor simultaneously.

---

## 7. Themes & Appearance Modes

MDView includes four carefully balanced visual themes to accommodate any lighting condition. Access them from the toolbar appearance menu or the Preferences panel (<kbd>⌘</kbd> <kbd>,</kbd>):

1. **System (Default)**: Automatically follows your macOS System Appearance, switching dynamically when macOS transitions between Light and Dark mode.
2. **Light**: Crisp, high-contrast white background with deep charcoal typography, ideal for bright office environments.
3. **Dark**: Deep slate/charcoal background with soft white text, minimizing eye strain during nighttime writing sessions.
4. **Sepia**: Warm, low-contrast parchment palette inspired by classic e-readers, designed for extended reading sessions.

---

## 8. Printing & Exporting to PDF

MDView provides print and vector PDF export engines that output clean, publication-ready documents:

- **Print (<kbd>⌘</kbd> <kbd>P</kbd>)**: Opens the standard macOS print dialog with full support for printer selection, layout orientation, page ranges, and headers/footers.
- **Export as PDF (<kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>E</kbd>)**: Generates a high-resolution, vector-based PDF file directly to your chosen disk location. Hyperlinks and headings are preserved in the generated PDF.
