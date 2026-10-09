import SwiftUI

@main
struct HyperkeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Bindable private var engine = HyperKeyEngine.shared

    var body: some Scene {
        MenuBarExtra("Hyperkey", systemImage: "command") {
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
        }
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
