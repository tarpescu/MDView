# MDView

A lightweight, modern, and native macOS Markdown reader and editor built with **SwiftUI** and **AppKit**. Designed specifically for macOS Sonoma (14.0+) following Apple's Human Interface Guidelines.

---

## ✨ Features

- **Safari-Style Tabbed Interface**: Multi-tab document management with sleek pill-shaped tabs, smooth tab switching, and independent window management.
- **Three Viewing Modes**:
  - **Viewer**: Beautiful GitHub Flavored Markdown (GFM) rendering powered by [`swift-markdown-ui`](https://github.com/gonzalezreal/swift-markdown-ui), with relative image support and clickable local document links.
  - **Editor**: High-performance native AppKit `NSTextView` with real-time paragraph-bounded regex syntax highlighting ($O(1)$ efficiency even on 5,000+ line documents).
  - **Split View**: Synchronized side-by-side editing and live rendered preview.
- **Interactive Table of Contents**: Automatically parses document headings (`H1`–`H6`) into an outline sidebar with one-click section navigation.
- **Real-Time Document Statistics**: Live status bar displaying character count, word count, and estimated reading time.
- **Themes & Appearances**: Full support for macOS System appearance, dedicated Light Mode, Dark Mode, and Sepia reading themes.
- **Dynamic Zoom & Font Scaling**: Smooth dynamic typography scaling via `Cmd` + `+`, `Cmd` + `-`, and `Cmd` + `0`.
- **Export & Print**: Native macOS print support and direct export to PDF.
- **System Integration**: Associated with Markdown file types (`.md`, `.markdown`, `.mdown`, `.txt`), supports Finder drag-and-drop, "Open With", and relative link resolution.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| <kbd>⌘</kbd> <kbd>N</kbd> | New Window |
| <kbd>⌘</kbd> <kbd>T</kbd> | New Tab |
| <kbd>⌘</kbd> <kbd>O</kbd> | Open File… |
| <kbd>⌘</kbd> <kbd>S</kbd> | Save Active Document |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>S</kbd> | Save Document As… |
| <kbd>⌘</kbd> <kbd>W</kbd> | Close Tab |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>W</kbd> | Close Window |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>]</kbd> | Next Tab |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>[</kbd> | Previous Tab |
| <kbd>⌘</kbd> <kbd>1</kbd> | Switch to Viewer Mode |
| <kbd>⌘</kbd> <kbd>2</kbd> | Switch to Split Mode |
| <kbd>⌘</kbd> <kbd>3</kbd> | Switch to Editor Mode |
| <kbd>⌘</kbd> <kbd>B</kbd> | Toggle **Bold** syntax |
| <kbd>⌘</kbd> <kbd>I</kbd> | Toggle *Italic* syntax |
| <kbd>⌘</kbd> <kbd>K</kbd> | Insert Markdown Link |
| <kbd>⌘</kbd> <kbd>+</kbd> / <kbd>⌘</kbd> <kbd>=</kbd> | Zoom In |
| <kbd>⌘</kbd> <kbd>-</kbd> | Zoom Out |
| <kbd>⌘</kbd> <kbd>0</kbd> | Actual Size (Reset Zoom) |
| <kbd>⌘</kbd> <kbd>P</kbd> | Print Document |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>E</kbd> | Export as PDF |
| <kbd>⌘</kbd> <kbd>,</kbd> | Preferences / Settings |

---

## 🛠 Requirements

- **macOS**: 14.0 (Sonoma) or newer
- **Swift**: 6.0 or newer
- **Xcode**: 16.0 or newer

---

## 🚀 Building & Running

### Using Swift Package Manager (CLI)

```bash
# Clone the repository
git clone https://github.com/tarpescu/MDView.git
cd MDView

# Build the project
swift build
```

### Using Xcode

1. Open the project folder in Xcode:
   ```bash
   xed .
   ```
2. Select the `MDView` executable target.
3. Press `Cmd` + `R` to build and run.

---

## 📦 Dependencies

- [`swift-markdown-ui`](https://github.com/gonzalezreal/swift-markdown-ui) (v2.4.0+) — Display and customize Markdown text in SwiftUI.

---

## 📄 License

This project is licensed under the MIT License.
