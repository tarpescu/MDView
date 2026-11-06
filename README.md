<div align="center">

# MDView

### The Native, Blazingly Fast macOS Markdown Reader & Editor

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma)-000000.svg?style=flat-square&logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138.svg?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Architecture: SwiftUI + AppKit](https://img.shields.io/badge/Architecture-SwiftUI%20%2B%20AppKit-007AFF.svg?style=flat-square)](docs/ARCHITECTURE.md)
[![Memory Footprint](https://img.shields.io/badge/Memory-~30MB%20RSS-34C759.svg?style=flat-square)](docs/ARCHITECTURE.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

<p align="center">
  <b>MDView</b> merges the distraction-free minimalism and near-zero memory footprint of TextEdit with the productivity of Safari-style tabbed browsing and live GitHub Flavored Markdown rendering. Built natively in Swift, SwiftUI, and AppKit with zero web-view overhead, it launches in milliseconds, sips battery, and delivers smooth 120 FPS editing.
</p>

[Key Features](#-key-features-matrix) • [Installation & Building](#-installation--building) • [Keyboard Shortcuts](#-keyboard-shortcuts-reference) • [Documentation](#-documentation-suite) • [Architecture](#-architecture-overview)

---

</div>

## ⚡ Key Features Matrix

| Feature | Specification | Detail |
| :--- | :--- | :--- |
| **Native Footprint** | ~30 MB idle RAM | Launches in under 100ms; consumes a fraction of Electron-based editors (500MB+). |
| **Hybrid Architecture** | Swift 6 + SwiftUI + AppKit | SwiftUI state-driven presentation paired with AppKit `NSTextView` for deterministic text layout. |
| **Safari-Style Tabs** | Multi-Tab Interface (`⌘T`) | Fluid pill-shaped tabs, dirty-state indicators, hover-reveal close buttons, and middle-click tab closure. |
| **Multi-Window System** | Independent Windows (`⌘N`) | Decoupled window instances with global event routing via `WindowManager`. |
| **Tri-Modal Workspace** | Viewer, Split, & Editor (`⌘1/2/3`) | Instant toggle between pure rendered Markdown, side-by-side editing, and raw source mode. |
| **Smart Link Resolver** | In-app Local `.md` Jumps | Relative Markdown links open as tabs in the active window without leaving the application. |
| **$O(1)$ Syntax Engine** | Paragraph-Bounded Highlighting | Sub-millisecond typing latency on 10,000+ line documents via custom `NSTextStorage`. |
| **Document Outline** | Interactive Table of Contents | Real-time `H1`–`H6` parser sidebar with animated smooth-scroll navigation. |
| **Live Telemetry** | Async Status Bar Statistics | Non-blocking, debounced word count, character count, and estimated reading time. |
| **Typography & Zoom** | Dynamic Font Scaling (`⌘+`/`⌘-`) | Continuous zoom from 70% to 250% scale across preview and editor buffers. |
| **Appearance & Output** | Themes & Native Export | System, Light, Dark, and Sepia themes with native macOS Print (`⌘P`) and PDF Export (`⇧⌘E`). |

---

## 🚀 Installation & Building

### Prerequisites

- **macOS**: Sonoma 14.0 or newer
- **IDE**: Xcode 15.0+ or Xcode 16.0+ (with Command Line Tools installed)
- **Toolchain**: Swift 6.0+

### Option 1: Open and Build in Xcode

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tarpescu/MDView.git
   cd MDView
   ```

2. **Open the project in Xcode:**
   ```bash
   open Package.swift
   # or run: xed .
   ```

3. **Select Scheme and Destination:**
   - In the Xcode toolbar, select the **MDView** executable target.
   - Choose **My Mac** as the run destination.

4. **Build and Run:**
   - Press <kbd>⌘</kbd> + <kbd>R</kbd> or click the **Play** button.

---

### Option 2: Build via Terminal (Swift Package Manager)

To compile an optimized release binary from the command line:

```bash
# Clone the repository
git clone https://github.com/tarpescu/MDView.git
cd MDView

# Build release configuration
swift build -c release

# Launch the compiled executable
.build/release/MDView
```

---

## ⌨️ Keyboard Shortcuts Reference

MDView adheres strictly to macOS Human Interface Guidelines, offering a comprehensive keyboard map for power users:

| Category | Shortcut | Action | Description |
| :--- | :--- | :--- | :--- |
| **Window & Tab** | <kbd>⌘</kbd> <kbd>N</kbd> | New Window | Spawns a new independent window instance |
| | <kbd>⌘</kbd> <kbd>T</kbd> | New Tab | Opens a new blank document tab in the current window |
| | <kbd>⌘</kbd> <kbd>W</kbd> | Close Tab | Closes active tab (closes window if last tab) |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>W</kbd> | Close Window | Immediately closes the active window and all its tabs |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>]</kbd> | Next Tab | Cycles forward through the tab bar |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>[</kbd> | Previous Tab | Cycles backward through the tab bar |
| **File Operations**| <kbd>⌘</kbd> <kbd>O</kbd> | Open File… | Displays native sheet to open files into tabs |
| | <kbd>⌘</kbd> <kbd>S</kbd> | Save | Writes changes directly to disk |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>S</kbd> | Save As… | Prompts for target location and filename |
| **Workspace Modes**| <kbd>⌘</kbd> <kbd>1</kbd> | Viewer Mode | Pure rendered GitHub Flavored Markdown view |
| | <kbd>⌘</kbd> <kbd>2</kbd> | Split Mode | Side-by-side live editor and rendered preview |
| | <kbd>⌘</kbd> <kbd>3</kbd> | Editor Mode | High-performance monospaced source editor |
| **Formatting** | <kbd>⌘</kbd> <kbd>B</kbd> | Bold Text | Encloses selection or cursor with `**` |
| | <kbd>⌘</kbd> <kbd>I</kbd> | Italic Text | Encloses selection or cursor with `*` |
| | <kbd>⌘</kbd> <kbd>K</kbd> | Insert Link | Formats selection as `[selection](url)` |
| **View & Zoom** | <kbd>⌘</kbd> <kbd>+</kbd> / <kbd>⌘</kbd> <kbd>=</kbd> | Zoom In | Scales typography up (+10% per step) |
| | <kbd>⌘</kbd> <kbd>-</kbd> | Zoom Out | Scales typography down (-10% per step) |
| | <kbd>⌘</kbd> <kbd>0</kbd> | Actual Size | Resets font scaling back to 100% |
| **Export & Print** | <kbd>⌘</kbd> <kbd>P</kbd> | Print… | Native macOS paginated print sheet |
| | <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>E</kbd> | Export as PDF…| Directly renders and exports document as PDF |
| **Preferences** | <kbd>⌘</kbd> <kbd>,</kbd> | Settings | Opens native macOS preferences panel |

---

## 📚 Documentation Suite

For deeper explorations into usage and technical design, consult our comprehensive documentation guides:

- **[User Guide (`docs/USAGE.md`)](docs/USAGE.md)**: In-depth manual covering the tri-modal workspace, Safari tab workflows, drag-and-drop file ingestion, smart relative link routing, Table of Contents navigation, and theme customization.
- **[Architecture & Developer Guide (`docs/ARCHITECTURE.md`)](docs/ARCHITECTURE.md)**: Deep technical dive into memory efficiency over Electron, the custom AppKit/SwiftUI window manager, the `OpenURLAction` link interceptor, and the $O(1)$ paragraph-bounded `NSTextStorage` regex engine.

---

## 🏛 Architecture Overview

```
                      ┌────────────────────────┐
                      │      MDViewApp         │
                      │  (@main / AppKit Adapt)│
                      └───────────┬────────────┘
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │   WindowManager    │          │    WindowGroup     │
       │ (Global Event Bus) │          │  (UUID Identifier) │
       └──────────┬─────────┘          └──────────┬─────────┘
                  │                               │
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │     WindowState    │◄─────────┤   WindowRootView   │
       │ (Tab State & FIFO) │          │  (Host Container)  │
       └──────────┬─────────┘          └──────────┬─────────┘
                  │                               │
                  ├───────────────────────────────┤
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │  SafariTabBarView  │          │    ContentView     │
       │ (Pill Tab Strip)   │          │ (Active Tab Host)  │
       └────────────────────┘          └──────────┬─────────┘
                                                  │
                 ┌────────────────────────────────┴────────────────┐
                 ▼                                                 ▼
      ┌─────────────────────┐                           ┌─────────────────────┐
      │ MarkdownPreviewView │                           │NativeMarkdownEditor │
      │(swift-markdown-ui + │                           │  (AppKit NSTextView │
      │OpenURL Interceptor) │                           │+ Paragraph Storage) │
      └─────────────────────┘                           └─────────────────────┘
```

---

## 📦 Dependencies

- [**swift-markdown-ui**](https://github.com/gonzalezreal/swift-markdown-ui) (v2.4.0+) — Clean, extensible Markdown rendering engine built on top of Apple's swift-cmark specification.

---

## 📄 License

MDView is released under the [MIT License](LICENSE). Contributions, feature requests, and bug reports are welcome.
