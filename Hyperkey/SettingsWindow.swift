import AppKit
import SwiftUI

/// Owns the single Settings window. Opened from the menu bar item and when the
/// app is reopened (needed when the menu bar icon is hidden in System Settings).
@MainActor
enum SettingsWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let newWindow = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            newWindow.title = "Hyperkey Settings"
            newWindow.styleMask = [.titled, .closable, .miniaturizable]
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
        }
        // Agent apps (no Dock icon) don't come to the front on their own.
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        // macOS may refuse to activate us (e.g. when launched from Terminal); still show the window on top.
        window?.orderFrontRegardless()
    }
}
