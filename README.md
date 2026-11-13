<div align="center">

<img src="docs/assets/icon.png" alt="MDView icon" width="128" height="128">

# MDView

### A native, lightweight macOS Markdown reader & editor

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma)-000000.svg?style=flat-square&logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138.svg?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Architecture: SwiftUI + AppKit](https://img.shields.io/badge/Architecture-SwiftUI%20%2B%20AppKit-007AFF.svg?style=flat-square)](docs/ARCHITECTURE.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

<p align="center">
  <b>MDView</b> combines the minimalism of TextEdit with Safari-style tabs and live GitHub Flavored Markdown rendering. It is a single native process written in Swift, SwiftUI and AppKit — no Electron, no embedded browser engine.
</p>

[Features](#-features) • [Install & Build](#-installation--building) • [Shortcuts](#%EF%B8%8F-keyboard-shortcuts) • [Documentation](#-documentation) • [Architecture](#-architecture-overview)

---

</div>

## ✨ Features

| Feature | Shortcut | Detail |
| :--- | :--- | :--- |
| **Safari-style tabs** | `⌘T` / `⌘W` | Pill tabs with unsaved-change dots, hover close buttons, middle-click to close, and a context menu (Close Other Tabs, Reveal in Finder, Copy Path). |
| **Multiple windows** | `⌘N` | Each window owns its own tabs; menu commands always target the frontmost window. |
| **Three workspace modes** | `⌘1` `⌘2` `⌘3` | Viewer (rendered), Split (editor + live preview), Editor (raw source). |
| **Session restore** | Settings → Startup | Reopens your windows and tabs on launch, including unsaved *Untitled* drafts. |
| **Smart links** | — | Relative `.md` links open as tabs, `#anchors` scroll to the heading (GitHub-style slugs), other files open in their default app. |
| **Document outline** | Toolbar ▸ sidebar | `H1`–`H6` outline (code blocks ignored); click to jump in Viewer or Editor. |
| **Native editor** | `⌘B` `⌘I` `⌘K` `⌘F` | `NSTextView` with paragraph-scoped syntax highlighting, formatting shortcuts and the system Find bar. |
| **Drag & drop** | — | Drop Markdown files onto a window to open them; drop images into the editor to insert `![](relative/path)`. |
| **Live statistics** | — | Debounced, off-main-thread word / character / line counts and reading time. |
| **Zoom & themes** | `⌘+` `⌘-` `⌘0` | 70 %–250 % zoom; System, Light, Dark and Sepia appearances. |
| **Local images** | — | `![](assets/diagram.png)` next to the document renders in the preview, print and PDF. |
| **Print & PDF** | `⌘P` / `⇧⌘E` | Paginated vector PDF (code blocks, tables, images included), always on white paper. |
| **No lost edits** | `⌘W` `⇧⌘W` `⌘Q` | Closing a tab, closing a window or quitting asks to save unsaved changes. |

---

## 🚀 Installation & Building

### Prerequisites

- **macOS** 14.0 (Sonoma) or newer
- **Xcode** 16 or newer — the full Xcode app, not only the Command Line Tools: recent SDKs implement SwiftUI's `@State` as a macro whose plugin ships with Xcode, so a Command-Line-Tools-only `swift build` fails with *“plugin for module 'SwiftUIMacros' not found”*.
- **Swift** 6.0+

> If `xcode-select -p` still points to `/Library/Developer/CommandLineTools`, either run `sudo xcode-select -s /Applications/Xcode.app` once, or prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. `scripts/build-app.sh` does the latter automatically.

### Option 1: Xcode

```bash
git clone https://github.com/tarpescu/MDView.git
cd MDView
open Package.swift   # or: xed .
```

Select the **MDView** scheme and **My Mac**, then press <kbd>⌘</kbd> <kbd>R</kbd>.

### Option 2: Build a real `.app` bundle (recommended for daily use)

```bash
scripts/build-app.sh            # creates build/MDView.app
scripts/build-app.sh --install  # …and copies it to /Applications
```

The script compiles a release build, wraps it with `Info.plist` (document types, bundle identifier), ad-hoc signs it and registers it with Launch Services, so MDView appears in Finder's **Open With** menu.

### Option 3: Run the bare executable

```bash
swift build -c release
.build/release/MDView
```

> **Note:** the bare executable has no `Info.plist`, so Finder integration (Open With, default app, Dock drops) is unavailable. Use Option 2 for that.

### Running the tests

```bash
swift test
```

The suite (Swift Testing) covers heading parsing and GitHub slugs, section splitting, multi-encoding file reading, the tab save/dirty-state model, statistics, zoom limits and PDF pagination.

---

## ⌨️ Keyboard Shortcuts

| Category | Shortcut | Action |
| :--- | :--- | :--- |
| **Window & Tab** | <kbd>⌘</kbd> <kbd>N</kbd> | New window |
| | <kbd>⌘</kbd> <kbd>T</kbd> | New tab |
| | <kbd>⌘</kbd> <kbd>W</kbd> | Close tab (closes the window after its last tab, quits after the app's last tab) |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>W</kbd> | Close window |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>]</kbd> / <kbd>[</kbd> | Next / previous tab |
| **File** | <kbd>⌘</kbd> <kbd>O</kbd> | Open… (multiple selection supported) |
| | <kbd>⌘</kbd> <kbd>S</kbd> | Save |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>S</kbd> | Save As… |
| **Modes** | <kbd>⌘</kbd> <kbd>1</kbd> / <kbd>2</kbd> / <kbd>3</kbd> | Viewer / Split / Editor |
| **Editor** | <kbd>⌘</kbd> <kbd>B</kbd> | Bold (`**…**`) |
| | <kbd>⌘</kbd> <kbd>I</kbd> | Italic (`*…*`) |
| | <kbd>⌘</kbd> <kbd>K</kbd> | Link (`[…](url)`, with `url` selected) |
| | <kbd>⌘</kbd> <kbd>F</kbd> | Find (<kbd>⌘</kbd> <kbd>G</kbd> next, <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>G</kbd> previous) |
| **View** | <kbd>⌘</kbd> <kbd>+</kbd> / <kbd>⌘</kbd> <kbd>=</kbd> | Zoom in (+10 %) |
| | <kbd>⌘</kbd> <kbd>-</kbd> | Zoom out (−10 %) |
| | <kbd>⌘</kbd> <kbd>0</kbd> | Actual size |
| **Output** | <kbd>⌘</kbd> <kbd>P</kbd> | Print… |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>E</kbd> | Export as PDF… |
| **App** | <kbd>⌘</kbd> <kbd>,</kbd> | Settings |

---

## 📚 Documentation

- **[User Guide](docs/USAGE.md)** — workspace modes, tabs and windows, links and anchors, session restore, outline, themes, printing.
- **[Architecture & Developer Guide](docs/ARCHITECTURE.md)** — window/tab state, session persistence, the link resolver, the AppKit editor bridge and highlighting engine, concurrency.
- **[Changelog](CHANGELOG.md)**

---

## 🏛 Architecture Overview

```
                      ┌────────────────────────┐
                      │       MDViewApp        │
                      │ (@main + AppDelegate)  │
                      └───────────┬────────────┘
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │   WindowManager    │          │    WindowGroup     │
       │ (routing, session) │          │  (UUID per window) │
       └──────────┬─────────┘          └──────────┬─────────┘
                  │                               │
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │    WindowState     │◄─────────┤   WindowRootView   │
       │  (tabs, selection) │          │  (host container)  │
       └──────────┬─────────┘          └──────────┬─────────┘
                  │                               │
                  ├───────────────────────────────┤
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │  SafariTabBarView  │          │    ContentView     │
       │  (pill tab strip)  │          │  (active tab host) │
       └────────────────────┘          └──────────┬─────────┘
                                                  │
                 ┌────────────────────────────────┴────────────────┐
                 ▼                                                 ▼
      ┌─────────────────────┐                           ┌─────────────────────┐
      │ MarkdownPreviewView │                           │NativeMarkdownEditor │
      │ (swift-markdown-ui +│                           │ (AppKit NSTextView +│
      │  link interceptor)  │                           │  highlighting store)│
      └─────────────────────┘                           └─────────────────────┘
```

### Project layout

```
Package.swift
scripts/build-app.sh            # release build → build/MDView.app
scripts/make-icon.swift         # renders the app icon (Core Graphics)
Sources/MDView/
├── MDViewApp.swift             # @main, AppDelegate, menu commands
├── Models/                     # TabItem, WindowState/WindowManager, headings, file I/O, printing
├── Views/                      # window root, tab bar, content, preview, editor, outline, status bar, settings
└── Resources/                  # Info.plist + AppIcon.icns (copied into the bundle by build-app.sh)
Tests/MDViewTests/              # swift test
docs/                           # USAGE.md, ARCHITECTURE.md
```

---

## 📦 Dependencies

- [**swift-markdown-ui**](https://github.com/gonzalezreal/swift-markdown-ui) (2.4+) — GitHub Flavored Markdown rendering in SwiftUI, built on [swift-cmark](https://github.com/swiftlang/swift-cmark).

---

## 🧭 Known Limitations

- Files changed on disk by another app are not reloaded automatically.
- The outline does not track the reading position while scrolling.
- Editor syntax highlighting works per paragraph, so lines inside fenced code blocks (e.g. `# comment`) are coloured like Markdown. The preview and outline handle them correctly.
- Remote (`https://`) images are not included in printouts and PDFs.

---

## 📄 License

MDView is released under the [MIT License](LICENSE). Contributions, feature requests and bug reports are welcome.
