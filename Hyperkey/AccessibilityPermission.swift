import AppKit
import ApplicationServices
import Observation

/// Tracks whether Hyperkey has Accessibility permission, which macOS requires
/// before an app may watch and change keypresses system-wide.
@MainActor
@Observable
final class AccessibilityPermission {
    static let shared = AccessibilityPermission()

    private(set) var isGranted = AXIsProcessTrusted()

    private init() {
        // macOS doesn't notify apps when this changes, so check every second.
        Task {
            while true {
                try? await Task.sleep(for: .seconds(1))
                let granted = AXIsProcessTrusted()
                if granted != isGranted { isGranted = granted }
            }
        }
    }

    func request() {
        // Adds Hyperkey to the Accessibility list (macOS also shows its own prompt the first time).
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
