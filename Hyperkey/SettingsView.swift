import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    private let permission = AccessibilityPermission.shared
    @Bindable private var engine = HyperKeyEngine.shared
    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle("Enable Hyper Key", isOn: $engine.isEnabled)
                Toggle("Open at Login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, open in
                        try? open ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        // Show what macOS actually did (it can refuse, or need approval in System Settings).
                        opensAtLogin = SMAppService.mainApp.status == .enabled
                    }
                Picker("Hyper key", selection: $engine.trigger) {
                    ForEach(TriggerKey.allCases) { key in
                        Text(key.name).tag(key)
                    }
                }
                Toggle("Notify When Switched with Esc", isOn: $engine.notifiesOnShortcut)
            } header: {
                Text("Hyper Key")
            } footer: {
                Text("Hold \(engine.trigger.name) to press ⌃⌥⇧⌘ all at once. Press \(engine.trigger.name) + Esc to switch it on or off.")
                    .foregroundStyle(.secondary)
            }
            Section {
                ForEach($engine.appShortcuts) { $shortcut in
                    HStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: shortcut.appURL.path))
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(shortcut.appName)
                        Spacer()
                        Picker("Key", selection: $shortcut.key) {
                            ForEach(AppShortcut.keys, id: \.self) { Text($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                        Button("Remove", systemImage: "minus.circle.fill") {
                            engine.appShortcuts.removeAll { $0.id == shortcut.id }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                    }
                }
                Button("Add App…", action: addApp)
            } header: {
                Text("App Shortcuts")
            } footer: {
                Text("Press \(engine.trigger.name) + a key to open its app.")
                    .foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("Accessibility") {
                    if permission.isGranted {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        HStack {
                            Text("Not granted")
                                .foregroundStyle(.secondary)
                            Button("Open System Settings…") {
                                permission.request()
                            }
                        }
                    }
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Hyperkey needs Accessibility access to read and change keypresses system-wide. Nothing you type is stored or sent anywhere.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 600)
    }

    /// Asks for an app, then gives it its first letter as the key (or the first free key if that's taken).
    private func addApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let used = Set(engine.appShortcuts.map(\.key))
        let firstLetter = url.lastPathComponent.prefix(1).uppercased()
        let key = [firstLetter] + AppShortcut.keys
        engine.appShortcuts.append(AppShortcut(
            key: key.first { AppShortcut.keyCodes[$0] != nil && !used.contains($0) } ?? "A",
            appURL: url
        ))
    }
}
