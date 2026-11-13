//
//  WindowCloseInterceptor.swift
//  MDView
//
//  Lets a SwiftUI window veto its own closing (red close button, ⇧⌘W,
//  performClose) so unsaved tabs can be saved first.
//
//  SwiftUI owns the NSWindow delegate, so instead of replacing it we install
//  a proxy that implements `windowShouldClose(_:)` and forwards every other
//  delegate message to SwiftUI's original delegate.
//

import SwiftUI
import AppKit

struct WindowCloseInterceptor: NSViewRepresentable {
    /// Return `false` to keep the window open.
    let shouldClose: @MainActor () -> Bool

    func makeNSView(context: Context) -> InterceptorView {
        let view = InterceptorView()
        view.shouldClose = shouldClose
        return view
    }

    func updateNSView(_ nsView: InterceptorView, context: Context) {
        nsView.shouldClose = shouldClose
    }

    final class InterceptorView: NSView {
        var shouldClose: (@MainActor () -> Bool)?
        private var proxy: WindowDelegateProxy?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            installProxyIfNeeded()
        }

        private func installProxyIfNeeded() {
            guard let window else { return }
            if let proxy, window.delegate === proxy { return }

            let newProxy = WindowDelegateProxy(original: window.delegate) { [weak self] in
                self?.shouldClose?() ?? true
            }
            // NSWindow.delegate is weak: the view keeps the proxy alive.
            proxy = newProxy
            window.delegate = newProxy
        }
    }
}

/// Forwards all NSWindowDelegate traffic to `original`, intercepting only
/// `windowShouldClose(_:)`.
@MainActor
final class WindowDelegateProxy: NSObject, NSWindowDelegate {
    // Read from the nonisolated ObjC forwarding overrides; only ever set in init.
    nonisolated(unsafe) private weak var original: NSWindowDelegate?
    private let shouldClose: @MainActor () -> Bool

    init(original: NSWindowDelegate?, shouldClose: @escaping @MainActor () -> Bool) {
        self.original = original
        self.shouldClose = shouldClose
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard shouldClose() else { return false }
        return original?.windowShouldClose?(sender) ?? true
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (original?.responds(to: aSelector) ?? false)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let original, original.responds(to: aSelector) { return original }
        return super.forwardingTarget(for: aSelector)
    }
}
