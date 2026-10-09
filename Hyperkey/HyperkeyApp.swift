import SwiftUI

@main
struct HyperkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Hyperkey", systemImage: "command") {
            Button("Settings…") {
                SettingsWindow.show()
            }
            .keyboardShortcut(",")
            Divider()
            Button("Quit Hyperkey") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Called when Hyperkey is opened again (Spotlight, Finder) while already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindow.show()
        return true
    }
}
