import CoreGraphics
import Foundation
import Observation

/// Turns Right ⌘ into a "Hyper" key: while it's held, key events are sent with
/// ⌃⌥⇧⌘ instead. Uses an event tap, a hook that sees (and can change) keyboard
/// events before apps do.
@MainActor
@Observable
final class HyperKeyEngine {
    static let shared = HyperKeyEngine()

    var isEnabled = UserDefaults.standard.object(forKey: "hyperKeyEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hyperKeyEnabled")
            update()
        }
    }

    /// The event callback is a plain C function, so it reads the tap from here.
    nonisolated(unsafe) fileprivate static var tap: CFMachPort?

    private let permission = AccessibilityPermission.shared
    private var runLoopSource: CFRunLoopSource?

    private init() {
        observePermission()
    }

    /// Starts or stops the event tap to match `isEnabled` and the permission.
    func update() {
        let shouldRun = isEnabled && permission.isGranted
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

/// Set in an event's flags while Right ⌘ is physically held (NX_DEVICERCMDKEYMASK).
private let rightCommandFlag: UInt64 = 0x10
private let hyperFlags: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]

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
        if event.flags.rawValue & rightCommandFlag != 0 {
            event.flags.formUnion(hyperFlags)
        }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
