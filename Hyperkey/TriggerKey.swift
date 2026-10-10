/// The physical key that acts as the Hyper key.
enum TriggerKey: String, CaseIterable, Identifiable {
    case rightCommand, rightOption, rightShift

    var id: Self { self }

    var name: String {
        switch self {
        case .rightCommand: "Right ⌘ Command"
        case .rightOption: "Right ⌥ Option"
        case .rightShift: "Right ⇧ Shift"
        }
    }

    /// Set in an event's flags while this exact key is physically held
    /// (macOS's NX_DEVICE…KEYMASK values).
    var deviceFlag: UInt64 {
        switch self {
        case .rightCommand: 0x10
        case .rightOption: 0x40
        case .rightShift: 0x04
        }
    }
}
