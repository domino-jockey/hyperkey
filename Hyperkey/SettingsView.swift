import SwiftUI

struct SettingsView: View {
    private let permission = AccessibilityPermission.shared
    @Bindable private var engine = HyperKeyEngine.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable Hyper Key", isOn: $engine.isEnabled)
            } header: {
                Text("Hyper Key")
            } footer: {
                Text("Hold Right ⌘ to press ⌃⌥⇧⌘ all at once.")
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
        .frame(width: 420, height: 320)
    }
}
