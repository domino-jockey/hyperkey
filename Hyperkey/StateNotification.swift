import UserNotifications

/// Shows a macOS notification saying whether Hyper is now on or off.
enum StateNotification {
    static func show(enabled: Bool) {
        Task {
            let center = UNUserNotificationCenter.current()
            // Asks for permission the first time; after that it just returns the answer.
            guard (try? await center.requestAuthorization(options: [.alert])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = enabled ? "Hyper Key On" : "Hyper Key Off"
            // Reusing one identifier replaces the last notification instead of piling them up.
            try? await center.add(UNNotificationRequest(identifier: "hyperState", content: content, trigger: nil))
        }
    }
}
