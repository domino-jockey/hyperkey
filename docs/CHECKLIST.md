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

- [ ] Handle "app reopened": opening Hyperkey again (Spotlight, Finder, Launchpad) while it's already running should open the Settings window. In code, that's `applicationShouldHandleReopen` in an `NSApplicationDelegate`.
- [ ] Make sure the Settings window comes to the front when opened (agent apps don't do this automatically, so call `NSApp.activate()`)
- [ ] Later (Phase 6): optionally add a Hyper shortcut that opens Settings, e.g. Hyper + `,`

**✅ Done when:** With the menu bar icon hidden in System Settings, opening Hyperkey from Spotlight brings up the Settings window.

---

## Phase 3 — Permissions

To read and change keypresses system-wide, macOS requires the user to grant permission.

- [ ] Check whether **Accessibility** permission is granted (`AXIsProcessTrusted()`)
- [ ] If it isn't, show a friendly screen in Settings explaining why it's needed, with a button that opens the right System Settings pane
- [ ] Detect when permission gets granted so the user doesn't have to restart the app (check again every so often, or whenever the window becomes active)
- [ ] Show the permission status in Settings (granted / not granted)

> Note: while you're developing, every rebuild can make macOS "forget" the permission because the app's signature changes. Signing with your Apple ID ("Development" signing in Xcode) mostly fixes this. If it still happens, remove Hyperkey from the Accessibility list and add it again.

**✅ Done when:** A fresh install asks for permission, and after you grant it the app notices without a restart.

---

## Phase 4 — The Hyper key (core feature)

How it works: the app installs an **event tap**, a hook that sees every keyboard event before other apps do and can change or block it.

- [ ] Create a `HyperKeyEngine` (one Swift file) that installs a `CGEventTap` for `keyDown`, `keyUp` and `flagsChanged` events
  - "flagsChanged" is the event macOS sends when a modifier key (⌘, ⌥, ⌃, ⇧, fn) goes down or up
- [ ] Detect **Right ⌘** specifically, as opposed to Left ⌘ (key code `54`, or the device-specific right-command flag)
- [ ] While Right ⌘ is held: add ⌘⌥⌃⇧ to every key event's modifier flags
- [ ] When Right ⌘ is released: stop adding them, and make sure no modifier stays "stuck"
- [ ] Left ⌘ must keep working exactly as normal
- [ ] Handle the tap getting disabled: macOS turns off taps that respond too slowly. Watch for `tapDisabledByTimeout` and turn it back on.
- [ ] Add an on/off toggle (a menu bar item and a Settings switch)

**Test:**
- [ ] Right ⌘ + key in a key-viewer app (or a shortcut-recording field) shows ⌃⌥⇧⌘ + key
- [ ] Left ⌘ + C / V still copy and paste normally
- [ ] Holding and releasing Right ⌘ quickly many times never leaves a modifier stuck
- [ ] Still works after sleep/wake

**✅ Done when:** Every test above passes.

---

## Phase 5 — Configurable trigger key

- [ ] Let the user choose which key acts as Hyper. Start with a dropdown: Right ⌘, Right ⌥, Right ⌃, Caps Lock, Right ⇧
- [ ] Save the choice (`UserDefaults`, macOS's simple built-in storage for settings)
- [ ] The engine picks up the change right away, without a restart
- [ ] Caps Lock needs special handling: it toggles on/off instead of being held. Leave it for last, or skip it in v1.

**✅ Done when:** Switching the trigger in Settings takes effect immediately, and the old key goes back to normal.

---

## Phase 6 — Shortcuts: opening apps

- [ ] Define a `Shortcut` data model: trigger key + extra modifiers (e.g. fn) + action
- [ ] Define an `Action` type that starts with `openApp(bundleID)`
- [ ] Save shortcuts as JSON (a simple text format for structured data) in `UserDefaults` or a file in Application Support
- [ ] In the engine: when Hyper + a bound key is pressed, **run the action and swallow the keypress** so other apps don't also receive it
- [ ] Unbound Hyper + key combos pass through as ⌃⌥⇧⌘ + key, so other apps (Raycast, etc.) can still use them
- [ ] Open apps with `NSWorkspace.shared.openApplication(at:configuration:)`
- [ ] Behavior if the app is already in front: decide between doing nothing and hiding it. **Decide:** ☐ nothing ☐ hide (toggle)
- [ ] Add starter shortcuts:
  - [ ] Hyper + G → Ghostty
  - [ ] Hyper + O → Obsidian

**✅ Done when:** Hyper + G opens or focuses Ghostty, Hyper + O opens or focuses Obsidian, and nothing else reacts to those keypresses.

---

## Phase 7 — Shortcuts settings UI

- [ ] A list of shortcuts in Settings (key combo on one side, action on the other)
- [ ] Add / edit / delete a shortcut
- [ ] **Key recorder:** click a field, press the key, and it records the combo
- [ ] **App picker:** choose an app from `/Applications` (a file picker, or a searchable list with app icons)
- [ ] Warn when two shortcuts use the same combo
- [ ] Changes take effect immediately

**✅ Done when:** You can create Hyper + S → Safari entirely from the UI, and it works right away.

---

## Phase 8 — More actions

- [ ] Extend `Action` with more types. Start with a few you'd actually use; candidates:
  - [ ] **Shut down** (and/or Restart, Sleep, Lock screen)
  - [ ] Open a URL or a folder
  - [ ] Run a shell script / terminal command
  - [ ] Run a Shortcut from Apple's Shortcuts app
- [ ] **Quick shutdown on fn + Hyper + Q:**
  - [ ] Detect fn being held (the "secondary fn" modifier flag) together with Hyper
  - [ ] Ask "Shut down now?" before shutting down, or not? **Decide:** ☐ confirm ☐ instant
  - [ ] Shut down via AppleScript (`tell application "System Events" to shut down`). The first time, macOS will ask for **Automation** permission.
- [ ] Each action type gets its own editor in the shortcuts UI

**✅ Done when:** fn + Hyper + Q shuts down (after confirmation, if chosen), and Hyper + Q alone does **not**.

---

## Phase 9 — General settings

- [ ] **Launch at login** toggle (`SMAppService.mainApp`, Apple's modern login-item API)
- [ ] Enable / disable Hyperkey toggle
- [ ] Permission status (from Phase 3)
- [ ] About section: version, and a "how to hide the menu bar icon" hint (System Settings → Menu Bar)
- [ ] Optional: export / import shortcuts as a file (backup)

**✅ Done when:** After a reboot, Hyperkey starts on its own and all shortcuts work.

---

## Phase 10 — Appearance & design (to be discussed)

Goal: feels native, has its own identity (not a copy of other hyperkey apps), and is consistent throughout.

- [ ] Design discussion: overall vibe, accent color, layout of the Settings window
- [ ] Settings layout: sidebar or tabs (General / Shortcuts / About)
- [ ] Use standard macOS controls (`Form`, `Toggle`, `Picker`) so it matches the system
- [ ] One accent color, one icon style, consistent spacing and wording everywhere
- [ ] Supports light and dark mode
- [ ] Custom app icon + menu bar icon
- [ ] Empty states (e.g. "No shortcuts yet — add one") and clear error messages

**✅ Done when:** Every screen follows the same style rules, and it looks right in both light and dark mode.

---

## Phase 11 — Polish & ship to yourself

- [ ] Test the full flow on a fresh user account: install → permission → set up shortcuts → reboot
- [ ] Check CPU usage while idle (it should be near 0%)
- [ ] Archive a release build in Xcode (Product → Archive) and copy `Hyperkey.app` to `/Applications`
- [ ] Optional: notarize it (Apple's malware check, needed if you share the app with others)
- [ ] Write a short `README.md`: what it does, permissions, how to hide the menu bar icon

**✅ Done when:** The release build in `/Applications` works for daily use.

---

## Later / ideas

- [ ] Per-app shortcuts (a combo that only applies in a specific app)
- [ ] Window management (Hyper + arrows to snap windows left/right)
- [ ] A small on-screen overlay listing your shortcuts while Hyper is held
- [ ] Tap the Hyper key alone to send another key, e.g. tap Right ⌘ = Escape
