//
//  NativeMarkdownEditorView.swift
//  MDView
//
//  A high-performance AppKit NSTextView wrapper for SwiftUI featuring:
//  - Custom NSTextStorage with paragraph-bounded regex syntax highlighting (O(1) on 5,000+ lines)
//  - Dynamic Font Scaling (Zoom) and Appearance theming (System, Light, Dark, Sepia)
//  - Markdown keyboard shortcuts: Cmd+B (Bold), Cmd+I (Italic), Cmd+K (Link), Cmd+1/2/3 (Mode switch)
//  - External programmatic scrolling to headings
//

import SwiftUI
import AppKit

@MainActor
struct NativeMarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollToOffset: Int?
    var fontScale: Double = 1.0
    var appearance: AppAppearance = .system
    var onModeSwitch: ((ViewMode) -> Void)?
    var isEditable: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let contentSize = scrollView.contentSize
        let textStorage = MarkdownTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = MarkdownTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.onModeSwitch = onModeSwitch

        // Typography & Configuration
        let baseFont = NSFont.monospacedSystemFont(ofSize: 13 * fontScale, weight: .regular)
        textView.font = baseFont
        textView.textColor = appearance.nsTextColor
        textView.backgroundColor = appearance.nsBackgroundColor
        textView.drawsBackground = (appearance != .system)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = isEditable
        textView.isSelectable = true

        // Disable smart formatting
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false

        // Padding & Line Wrapping
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        // Load initial text and configure storage typography
        textStorage.updateTypography(scale: fontScale, appearance: appearance)
        textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownTextView,
              let textStorage = textView.textStorage as? MarkdownTextStorage else { return }

        // Synchronize external text changes
        if textStorage.string != text {
            let previousRanges = textView.selectedRanges
            textStorage.replaceCharacters(in: NSRange(location: 0, length: (textStorage.string as NSString).length), with: text)
            
            if let firstRange = previousRanges.first?.rangeValue,
               firstRange.location + firstRange.length <= text.utf16.count {
                textView.selectedRanges = previousRanges
            }
        }

        // Synchronize font scale & appearance
        if textStorage.currentScale != fontScale || textStorage.currentAppearance != appearance {
            let newFont = NSFont.monospacedSystemFont(ofSize: 13 * fontScale, weight: .regular)
            textView.font = newFont
            textView.textColor = appearance.nsTextColor
            textView.backgroundColor = appearance.nsBackgroundColor
            textView.drawsBackground = (appearance != .system)
            textStorage.updateTypography(scale: fontScale, appearance: appearance)
        }

        // Programmatic scroll-to-heading from Table of Contents
        if let offset = scrollToOffset {
            let safeLocation = min(offset, (textStorage.string as NSString).length)
            let targetRange = NSRange(location: safeLocation, length: 0)
            textView.scrollRangeToVisible(targetRange)
            textView.setSelectedRange(targetRange)

            DispatchQueue.main.async {
                self.scrollToOffset = nil
            }
        }

        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }

        textView.onModeSwitch = onModeSwitch
    }

    // MARK: - Coordinator
    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeMarkdownEditorView

        init(_ parent: NativeMarkdownEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if parent.text != textView.string {
                parent.text = textView.string
            }
        }
    }
}

// MARK: - Custom NSTextView with Markdown Formatting Shortcuts
final class MarkdownTextView: NSTextView {
    var onModeSwitch: ((ViewMode) -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }

        switch event.charactersIgnoringModifiers {
        case "b", "B":
            wrapSelection(with: "**")
            return true
        case "i", "I":
            wrapSelection(with: "*")
            return true
        case "k", "K":
            insertMarkdownLink()
            return true
        case "1":
            onModeSwitch?(.viewer)
            return true
        case "2":
            onModeSwitch?(.split)
            return true
        case "3":
            onModeSwitch?(.editor)
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    private func wrapSelection(with prefix: String, suffix: String? = nil) {
        let closing = suffix ?? prefix
        let currentRange = selectedRange()
        guard let storage = textStorage else { return }
        let nsString = storage.string as NSString

        if currentRange.length > 0 && currentRange.location + currentRange.length <= nsString.length {
            let selectedText = nsString.substring(with: currentRange)
            let replacement = "\(prefix)\(selectedText)\(closing)"
            if shouldChangeText(in: currentRange, replacementString: replacement) {
                replaceCharacters(in: currentRange, with: replacement)
                didChangeText()
                setSelectedRange(NSRange(location: currentRange.location + prefix.count, length: currentRange.length))
            }
        } else {
            let replacement = "\(prefix)\(closing)"
            if shouldChangeText(in: currentRange, replacementString: replacement) {
                replaceCharacters(in: currentRange, with: replacement)
                didChangeText()
                setSelectedRange(NSRange(location: currentRange.location + prefix.count, length: 0))
            }
        }
    }

    private func insertMarkdownLink() {
        let currentRange = selectedRange()
        guard let storage = textStorage else { return }
        let nsString = storage.string as NSString

        if currentRange.length > 0 && currentRange.location + currentRange.length <= nsString.length {
            let selectedText = nsString.substring(with: currentRange)
            let replacement = "[\(selectedText)](url)"
            if shouldChangeText(in: currentRange, replacementString: replacement) {
                replaceCharacters(in: currentRange, with: replacement)
                didChangeText()
                let urlLocation = currentRange.location + selectedText.count + 3
                setSelectedRange(NSRange(location: urlLocation, length: 3))
            }
        } else {
            let replacement = "[](url)"
            if shouldChangeText(in: currentRange, replacementString: replacement) {
                replaceCharacters(in: currentRange, with: replacement)
                didChangeText()
                setSelectedRange(NSRange(location: currentRange.location + 1, length: 0))
            }
        }
    }
}

// MARK: - High-Performance NSTextStorage Subclass with Scaling
final class MarkdownTextStorage: NSTextStorage {
    private let backingStore = NSMutableAttributedString()

    var currentScale: Double = 1.0
    var currentAppearance: AppAppearance = .system

    private static let headerRegex = try! NSRegularExpression(pattern: #"^(#{1,6})[ \t]+(.*)$"#, options: .anchorsMatchLines)
    private static let boldRegex = try! NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#, options: [])
    private static let italicRegex = try! NSRegularExpression(pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, options: [])
    private static let inlineCodeRegex = try! NSRegularExpression(pattern: #"`([^`\n]+)`"#, options: [])
    private static let linkRegex = try! NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, options: [])

    private var defaultFont: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    private var boldFont: NSFont = .monospacedSystemFont(ofSize: 13, weight: .bold)
    private var italicFont: NSFont = {
        let descriptor = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular).fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    }()

    func updateTypography(scale: Double, appearance: AppAppearance) {
        self.currentScale = scale
        self.currentAppearance = appearance
        let size = 13.0 * scale
        self.defaultFont = .monospacedSystemFont(ofSize: size, weight: .regular)
        self.boldFont = .monospacedSystemFont(ofSize: size, weight: .bold)
        let descriptor = NSFont.monospacedSystemFont(ofSize: size, weight: .regular).fontDescriptor.withSymbolicTraits(.italic)
        self.italicFont = NSFont(descriptor: descriptor, size: size) ?? defaultFont

        applySyntaxHighlighting(forceFull: true)
    }

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        backingStore.replaceCharacters(in: range, with: str)
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: (str as NSString).length - range.length)
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    override func processEditing() {
        applySyntaxHighlighting(forceFull: false)
        super.processEditing()
    }

    private func applySyntaxHighlighting(forceFull: Bool = false) {
        let nsString = backingStore.string as NSString
        let totalLength = nsString.length
        guard totalLength > 0 else { return }

        let targetRange: NSRange
        if !forceFull && editedRange.location != NSNotFound && editedRange.location <= totalLength {
            let safeLocation = min(editedRange.location, max(0, totalLength - 1))
            let safeLength = min(editedRange.length, totalLength - safeLocation)
            targetRange = nsString.paragraphRange(for: NSRange(location: safeLocation, length: safeLength))
        } else {
            targetRange = NSRange(location: 0, length: totalLength)
        }

        let textColor = currentAppearance.nsTextColor
        let linkColor = currentAppearance == .sepia ? NSColor(red: 0.72, green: 0.35, blue: 0.12, alpha: 1.0) : NSColor.linkColor
        let codeBg = currentAppearance == .sepia ? NSColor(red: 0.92, green: 0.88, blue: 0.79, alpha: 1.0) : NSColor.quaternaryLabelColor.withAlphaComponent(0.35)

        // 1. Base attributes
        backingStore.setAttributes([
            .font: defaultFont,
            .foregroundColor: textColor
        ], range: targetRange)

        // 2. Headers
        Self.headerRegex.enumerateMatches(in: nsString as String, options: [], range: targetRange) { match, _, _ in
            guard let match = match, match.numberOfRanges >= 3 else { return }
            let hashRange = match.range(at: 1)
            let textRange = match.range(at: 2)

            backingStore.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: hashRange)
            backingStore.addAttribute(.font, value: self.boldFont, range: hashRange)

            backingStore.addAttribute(.font, value: self.boldFont, range: textRange)
            backingStore.addAttribute(.foregroundColor, value: textColor, range: textRange)
        }

        // 3. Bold
        Self.boldRegex.enumerateMatches(in: nsString as String, options: [], range: targetRange) { match, _, _ in
            guard let match = match, match.numberOfRanges >= 2 else { return }
            let innerRange = match.range(at: 1)
            backingStore.addAttribute(.font, value: self.boldFont, range: innerRange)
        }

        // 4. Italics
        Self.italicRegex.enumerateMatches(in: nsString as String, options: [], range: targetRange) { match, _, _ in
            guard let match = match, match.numberOfRanges >= 2 else { return }
            let innerRange = match.range(at: 1)
            backingStore.addAttribute(.font, value: self.italicFont, range: innerRange)
        }

        // 5. Inline Code
        Self.inlineCodeRegex.enumerateMatches(in: nsString as String, options: [], range: targetRange) { match, _, _ in
            guard let match = match else { return }
            backingStore.addAttribute(.foregroundColor, value: NSColor.systemTeal, range: match.range)
            backingStore.addAttribute(.backgroundColor, value: codeBg, range: match.range)
        }

        // 6. Links
        Self.linkRegex.enumerateMatches(in: nsString as String, options: [], range: targetRange) { match, _, _ in
            guard let match = match, match.numberOfRanges >= 3 else { return }
            let titleRange = match.range(at: 1)
            let urlRange = match.range(at: 2)

            backingStore.addAttribute(.foregroundColor, value: linkColor, range: titleRange)
            backingStore.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: titleRange)
            backingStore.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: urlRange)
        }
    }
}
