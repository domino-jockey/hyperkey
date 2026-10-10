import ServiceManagement
import SwiftUI

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
        .frame(width: 420, height: 440)
    }
}
