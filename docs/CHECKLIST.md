# Hyperkey — Build Checklist

A native macOS menu bar app (Swift + SwiftUI) that turns a chosen key (default: Right ⌘) into a "Hyper" key (⌘⌥⌃⇧), and lets you bind Hyper + key to actions like opening apps.

See [PROMPT.md](PROMPT.md) for the original idea.

Each phase ends with a **✅ Done when** check. Don't move on until it passes.

---

## Phase 0 — Decisions (before coding)

- [x] Minimum macOS version: **macOS 27** (the version you're on; no need to support older Macs for a personal app)
- [x] App name **Hyperkey**, bundle ID `com.jammyjellyfish.Hyperkey`. The bundle ID is the app's unique internal name, and macOS ties permissions to it.
- [x] Distribution: **personal use / direct download, not the Mac App Store.** Apps that watch the keyboard system-wide can't run in the App Store's "sandbox" (a locked-down mode that blocks that kind of access).
- [x] `git init` the project so there's a history to roll back to

---

## Phase 1 — Project skeleton

- [x] Describe the Xcode project in `project.yml` and generate `Hyperkey.xcodeproj` with **XcodeGen** (a tool that builds the Xcode project file from a short readable text file). After changing `project.yml` or adding files, run `xcodegen` again.
- [x] Turn **off** App Sandbox (`ENABLE_APP_SANDBOX: NO`)
- [x] Hide the Dock icon (`LSUIElement` = `YES`)
- [x] Replace the default window with a `MenuBarExtra` (the SwiftUI way to put an icon in the menu bar), with:
  - [x] "Settings…" item
  - [x] "Quit Hyperkey" item
- [x] Add a SwiftUI `Settings` scene (an empty settings window for now)
- [x] Use a placeholder SF Symbol (Apple's built-in icon set) for the menu bar icon: `command`

**✅ Done when:** Running the app shows an icon in the menu bar and no Dock icon, "Settings…" opens a window, and "Quit" quits.

---

## Phase 2 — Reopening when the menu bar icon is hidden

You plan to hide the icon using macOS's own System Settings → Menu Bar (the "don't allow in menu bar" toggle). Once it's hidden, the app still needs a way to get back to Settings.

- [x] Handle "app reopened": opening Hyperkey again (Spotlight, Finder, Launchpad) while it's already running should open the Settings window. In code, that's `applicationShouldHandleReopen` in an `NSApplicationDelegate`.
- [x] Make sure the Settings window comes to the front when opened (agent apps don't do this automatically, so call `NSApp.activate()`, plus `orderFrontRegardless()` for when macOS refuses to switch apps, e.g. launched from Terminal)
- [x] ~~Hyper shortcut to open Settings~~: dropped, since reopening from Spotlight already does it

**✅ Done when:** With the menu bar icon hidden in System Settings, opening Hyperkey from Spotlight brings up the Settings window.

---

## Phase 3 — Permissions

To read and change keypresses system-wide, macOS requires the user to grant permission.

- [x] Check whether **Accessibility** permission is granted (`AXIsProcessTrusted()`)
- [x] If it isn't, show a friendly screen in Settings explaining why it's needed, with a button that opens the right System Settings pane
- [x] Detect when permission gets granted so the user doesn't have to restart the app (check again every so often, or whenever the window becomes active)
- [x] Show the permission status in Settings (granted / not granted)

- [x] Stable code signing: builds are signed with a self-made **"Hyperkey Local"** certificate in the login keychain, so macOS keeps the permission across rebuilds. (Ad-hoc signing gave every build a new identity, and macOS forgot the permission each time.) To undo: delete "Hyperkey Local" in Keychain Access.

**✅ Done when:** A fresh install asks for permission, and after you grant it the app notices without a restart.

---

## Phase 4 — The Hyper key (core feature)

How it works: the app installs an **event tap**, a hook that sees every keyboard event before other apps do and can change or block it.

- [x] Create a `HyperKeyEngine` (one Swift file) that installs a `CGEventTap` for `keyDown`, `keyUp` and `flagsChanged` events
  - "flagsChanged" is the event macOS sends when a modifier key (⌘, ⌥, ⌃, ⇧, fn) goes down or up
- [x] Detect **Right ⌘** specifically, as opposed to Left ⌘ (using the device-specific right-command flag `0x10` that every key event carries, so no "held" state is stored and nothing can get stuck)
- [x] While Right ⌘ is held: add ⌘⌥⌃⇧ to every key event's modifier flags
- [x] When Right ⌘ is released: stop adding them, and make sure no modifier stays "stuck"
- [x] Left ⌘ must keep working exactly as normal
- [x] Handle the tap getting disabled: macOS turns off taps that respond too slowly. Watch for `tapDisabledByTimeout` and turn it back on.
- [x] Add an on/off toggle (a menu bar item and a Settings switch)

**Test:**
- [x] Right ⌘ + key in a key-viewer app (or a shortcut-recording field) shows ⌃⌥⇧⌘ + key
- [x] Left ⌘ + C / V still copy and paste normally
- [x] Holding and releasing Right ⌘ quickly many times never leaves a modifier stuck
- [ ] Still works after sleep/wake (not tested yet)

**✅ Done when:** Every test above passes.

---

## Phase 5 — Configurable trigger key

- [x] Let the user choose which key acts as Hyper, from a dropdown: Right ⌘, Right ⌥, Right ⇧ (no Right ⌃, because this keyboard doesn't have one)
- [x] Save the choice (`UserDefaults`, macOS's simple built-in storage for settings)
- [x] The engine picks up the change right away, without a restart
- [x] ~~Caps Lock~~: skipped, because Caps Lock is already remapped to Esc

**✅ Done when:** Switching the trigger in Settings takes effect immediately, and the old key goes back to normal.

---

## Phase 6 — Emergency on/off shortcut

Opening apps and other actions (the original Phases 6–9) are dropped: the Shortcuts app already does that, using Hyper key combos. Appearance (the original Phase 10) is dropped too: the built-in look is good enough, and the menu bar icon stays hidden.

- [x] Trigger + Esc switches Hyper on or off, and the keypress is swallowed so no app sees it
- [x] The event tap keeps running while Hyper is off, so the shortcut can switch it back on
- [x] Holding the combo down doesn't toggle it over and over (key repeats are ignored)

**✅ Done when:** Trigger + Esc turns Hyper off and back on, and the toggle in Settings follows along.

---

## Phase 7 — Polish & ship to yourself

- [x] Check CPU usage while idle: 0.0% CPU, about 20 MB of memory
- [x] Build a release version and copy `Hyperkey.app` to `/Applications`
- [x] Write a short `README.md`: what it does, permissions, the on/off shortcut, how to hide the menu bar icon, start at login
- [x] "Open at Login" toggle in Settings (`SMAppService.mainApp`, Apple's login-item API)
- [ ] Turn it on, reboot, and check Hyperkey starts and works
- [x] ~~Fresh user account test, notarizing~~: skipped, since this is a personal app

**✅ Done when:** The release build in `/Applications` works for daily use.
