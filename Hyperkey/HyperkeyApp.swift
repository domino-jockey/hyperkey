import SwiftUI

@main
struct HyperkeyApp: App {
    var body: some Scene {
        MenuBarExtra("Hyperkey", systemImage: "command") {
            MenuContent()
        }
        Settings {
            SettingsView()
        }
    }
}

struct MenuContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            // Agent apps (no Dock icon) don't come to the front on their own.
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Hyperkey") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
