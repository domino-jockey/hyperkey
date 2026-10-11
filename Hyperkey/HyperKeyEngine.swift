import AppKit
import CoreGraphics
import Foundation
import Observation

/// Turns the trigger key (Right ⌘ by default) into a "Hyper" key: while it's held, key events are sent with
/// ⌃⌥⇧⌘ instead. Uses an event tap, a hook that sees (and can change) keyboard
/// events before apps do.
@MainActor
@Observable
final class HyperKeyEngine {
    static let shared = HyperKeyEngine()

    var isEnabled = UserDefaults.standard.object(forKey: "hyperKeyEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hyperKeyEnabled")
            Self.hyperEnabled = isEnabled
        }
    }

    var notifiesOnShortcut = UserDefaults.standard.object(forKey: "notifiesOnShortcut") as? Bool ?? true {
        didSet { UserDefaults.standard.set(notifiesOnShortcut, forKey: "notifiesOnShortcut") }
    }

    var trigger = TriggerKey(rawValue: UserDefaults.standard.string(forKey: "triggerKey") ?? "") ?? .rightCommand {
        didSet {
            UserDefaults.standard.set(trigger.rawValue, forKey: "triggerKey")
            Self.triggerFlag = trigger.deviceFlag
        }
    }

    var appShortcuts: [AppShortcut] = (UserDefaults.standard.data(forKey: "appShortcuts"))
        .flatMap { try? JSONDecoder().decode([AppShortcut].self, from: $0) } ?? [] {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(appShortcuts), forKey: "appShortcuts")
            Self.appsByKeyCode = Self.lookup(appShortcuts)
        }
    }

    /// The event callback is a plain C function, so it reads the tap and settings from here.
    nonisolated(unsafe) fileprivate static var tap: CFMachPort?
    nonisolated(unsafe) fileprivate static var triggerFlag: UInt64 = 0
    nonisolated(unsafe) fileprivate static var hyperEnabled = true
    nonisolated(unsafe) fileprivate static var appsByKeyCode: [Int64: URL] = [:]

    private let permission = AccessibilityPermission.shared
    private var runLoopSource: CFRunLoopSource?

    private init() {
        Self.triggerFlag = trigger.deviceFlag
        Self.hyperEnabled = isEnabled
        Self.appsByKeyCode = Self.lookup(appShortcuts)
        observePermission()
    }

    /// Starts or stops the event tap to match the permission. The tap keeps running while
    /// Hyper is switched off, so trigger + Esc can switch it back on.
    func update() {
        let shouldRun = permission.isGranted
        if shouldRun && Self.tap == nil {
            start()
        } else if !shouldRun && Self.tap != nil {
            stop()
        }
    }

    private func start() {
        let events: [CGEventType] = [.keyDown, .keyUp, .flagsChanged]
        let mask = events.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: handleEvent,
            userInfo: nil
        ) else { return }
        Self.tap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }

    private func stop() {
        guard let tap = Self.tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CFMachPortInvalidate(tap)
        Self.tap = nil
        runLoopSource = nil
    }

    /// If two shortcuts use the same key, the first one wins.
    private static func lookup(_ shortcuts: [AppShortcut]) -> [Int64: URL] {
        shortcuts.reduce(into: [:]) { result, shortcut in
            if let code = AppShortcut.keyCodes[shortcut.key], result[code] == nil {
                result[code] = shortcut.appURL
            }
        }
    }

    /// Re-runs `update()` whenever the Accessibility permission changes.
    private func observePermission() {
        withObservationTracking {
            _ = permission.isGranted
        } onChange: {
            Task { @MainActor in
                self.update()
                self.observePermission()
            }
        }
    }
}

private let hyperFlags: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
private let escapeKeyCode: Int64 = 53

private func handleEvent(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        // macOS switches off taps it thinks are too slow; turn ours back on.
        if let tap = HyperKeyEngine.tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    case .keyDown, .keyUp, .flagsChanged:
        // Each event carries the real modifier state, so no "is Hyper held" state is kept,
        // and nothing can get stuck.
        let triggerHeld = event.flags.rawValue & HyperKeyEngine.triggerFlag != 0
        // Trigger + Esc switches Hyper on or off, and no app sees the keypress.
        if triggerHeld && type != .flagsChanged
            && event.getIntegerValueField(.keyboardEventKeycode) == escapeKeyCode {
            if type == .keyDown && event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                // The tap runs on the main run loop, so this is already the main thread.
                MainActor.assumeIsolated {
                    let engine = HyperKeyEngine.shared
                    engine.isEnabled.toggle()
                    if engine.notifiesOnShortcut {
                        StateNotification.show(enabled: engine.isEnabled)
                    }
                }
            }
            return nil
        }
        // Hyper + a key with an app assigned opens that app, and no app sees the keypress.
        if triggerHeld && HyperKeyEngine.hyperEnabled && type != .flagsChanged,
           let appURL = HyperKeyEngine.appsByKeyCode[event.getIntegerValueField(.keyboardEventKeycode)] {
            if type == .keyDown && event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                NSWorkspace.shared.openApplication(at: appURL, configuration: .init())
            }
            return nil
        }
        if triggerHeld && HyperKeyEngine.hyperEnabled {
            event.flags.formUnion(hyperFlags)
        }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
