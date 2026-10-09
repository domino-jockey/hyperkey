import SwiftUI

struct SettingsView: View {
    private let permission = AccessibilityPermission.shared

    var body: some View {
        Form {
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
        .frame(width: 420, height: 260)
    }
}
