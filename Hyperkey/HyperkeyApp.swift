import SwiftUI

@main
struct HyperkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Bindable private var engine = HyperKeyEngine.shared

    var body: some Scene {
        MenuBarExtra {
            Toggle("Enable Hyper Key", isOn: $engine.isEnabled)
            Divider()
            Button("Settings…") {
                SettingsWindow.show()
            }
            .keyboardShortcut(",")
            Divider()
            Button("Quit Hyperkey") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: menuBarIcon(dimmed: !engine.isEnabled))
        }
    }

    // The menu bar ignores SwiftUI's .opacity, so draw the symbol faded into its own image.
    // Template images are tinted by macOS, so the faded version shows up gray.
    private func menuBarIcon(dimmed: Bool) -> NSImage {
        let symbol = NSImage(systemSymbolName: "command", accessibilityDescription: "Hyperkey")!
        let icon = NSImage(size: symbol.size, flipped: false) { rect in
            symbol.draw(in: rect, from: .zero, operation: .sourceOver, fraction: dimmed ? 0.35 : 1)
            return true
        }
        icon.isTemplate = true
        return icon
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        HyperKeyEngine.shared.update()
    }

    // Called when Hyperkey is opened again (Spotlight, Finder) while already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindow.show()
        return true
    }
}
