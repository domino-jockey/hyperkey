import Foundation

/// Hyper + `key` opens the app at `appURL`.
struct AppShortcut: Codable, Identifiable, Hashable {
    var id = UUID()
    var key: String
    var appURL: URL

    var appName: String { appURL.deletingPathExtension().lastPathComponent }

    /// The keys you can pick, mapped to macOS's key codes (positions on a US keyboard).
    static let keyCodes: [String: Int64] = [
        "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7, "C": 8, "V": 9,
        "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16, "T": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "9": 25, "7": 26, "8": 28, "0": 29,
        "O": 31, "U": 32, "I": 34, "P": 35, "L": 37, "J": 38, "K": 40, "N": 45, "M": 46,
    ]

    static let keys = keyCodes.keys.sorted { ($0.first!.isNumber ? 1 : 0, $0) < ($1.first!.isNumber ? 1 : 0, $1) }
}
