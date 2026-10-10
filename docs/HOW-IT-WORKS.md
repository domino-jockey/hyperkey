# How Hyperkey works

A guide to how a Swift Mac app is put together, using Hyperkey as the example. Read it top to bottom once, then use it as a reference.

---

## 1. The big picture

- **Swift** is the programming language. Every `.swift` file is Swift code.
- **SwiftUI** is Apple's toolkit for building windows, buttons and switches. You describe what the screen should look like, and SwiftUI draws it and keeps it up to date.
- **AppKit** is the older Mac toolkit that SwiftUI sits on top of. Hyperkey uses it in a few places where SwiftUI can't do the job, like managing the Settings window.
- **A Mac app is a folder.** `Hyperkey.app` looks like one file in Finder, but it's a folder (a "bundle") holding the compiled program, the `Info.plist` and a code signature. Right-click it → Show Package Contents to look inside.

---

## 2. The tools, and what `make` does for you

| Tool           | What it is                                                                                                   |
|----------------|--------------------------------------------------------------------------------------------------------------|
| **Xcode**      | Apple's app for writing and building Mac/iPhone apps. You don't need to open it, but it has to be installed. |
| **xcodebuild** | Xcode's command-line version. It turns the Swift files into `Hyperkey.app`.                                  |
| **XcodeGen**   | Creates `Hyperkey.xcodeproj` (the project file Xcode needs) from the short, readable `project.yml`.          |
| **make**       | Runs the shortcuts in `Makefile`, so you don't have to remember the commands above.                          |

```
project.yml ──xcodegen──▶ Hyperkey.xcodeproj ──xcodebuild──▶ build/…/Hyperkey.app
```

| Command        | What it does                                                                       |
|----------------|------------------------------------------------------------------------------------|
| `make run`     | Builds a **Debug** (test) version and opens it                                    |
| `make install` | Builds a **Release** (finished) version, copies it to `/Applications` and opens it |
| `make clean`   | Deletes `build/` and `Hyperkey.xcodeproj`. Both come back on the next build.       |

**Debug vs Release:** Debug builds faster and is easier to investigate when something breaks. Release is optimised and is the one you use day to day. Both close any running Hyperkey before opening the new one, so you never have two running at once.

`build/` and `Hyperkey.xcodeproj` are listed in `.gitignore`, so git ignores them. They're generated, so there's no point saving them.

---

## 3. The files

| File                                     | Job                                                                                    |
|------------------------------------------|----------------------------------------------------------------------------------------|
| `project.yml`                            | Settings for the project: app name, bundle ID, macOS version, signing, "no Dock icon". |
| `Hyperkey/HyperkeyApp.swift`             | **Starting point.** Creates the menu bar menu and runs setup when the app launches.    |
| `Hyperkey/HyperKeyEngine.swift`          | **The core.** Watches every keypress and adds ⌃⌥⇧⌘ while the trigger key is held.      |
| `Hyperkey/TriggerKey.swift`              | The list of keys you can pick as the trigger (Right ⌘ / ⌥ / ⇧).                        |
| `Hyperkey/SettingsView.swift`            | What the Settings window shows: switches, the trigger picker, permission status.       |
| `Hyperkey/SettingsWindow.swift`          | Opens the Settings window and brings it to the front.                                  |
| `Hyperkey/AccessibilityPermission.swift` | Checks whether macOS has given the app permission to see keypresses.                   |
| `Hyperkey/Info.plist`                    | Basic facts macOS reads about the app (name, version, "this is a menu bar app").       |

---

## 4. What happens when Hyperkey starts

1. macOS runs the code marked `@main` in `HyperkeyApp.swift`.
2. That puts the icon and menu in the menu bar (`MenuBarExtra`).
3. `applicationDidFinishLaunching` runs and tells the engine to start.
4. The engine checks the permission. If permission is granted, it installs the **event tap**.
5. From then on, the app just waits. It uses no CPU until a key is pressed.

---

## 5. How a keypress gets changed

An **event tap** is a hook macOS lets you put into the keyboard stream. Every key event passes through Hyperkey's `handleEvent` function before any app sees it.

```
you press a key ──▶ macOS ──▶ handleEvent (Hyperkey) ──▶ the app you're using
```

Every key event carries **flags**: a record of which modifier keys (⌘ ⌥ ⌃ ⇧) are held at that moment. They even record which side of the keyboard a modifier is on: Right ⌘ has its own flag (`0x10`, a number written in hexadecimal).

For each key event, `handleEvent` does this:

1. **Is the trigger key held?** It checks the trigger's flag on the event.
2. **Is the key Esc?** If so, it switches Hyper on or off and returns `nil`, which means "throw this event away", so no app sees it.
3. **Otherwise, if Hyper is on,** it adds ⌃⌥⇧⌘ to the flags and passes the event on.

Hyperkey never remembers whether the trigger key is held; it reads the flags fresh on every event. That's why a modifier can't get "stuck".

Hyperkey turns the tap back on whenever macOS switches it off (macOS does that to hooks it thinks are too slow).

---

## 6. Swift words you'll see in the code

| Word                             | Meaning                                                                                                           |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `struct` / `class` / `enum`      | Ways to define a new type of thing. `enum` is a fixed list of choices, like `TriggerKey`.                         |
| `var` / `let`                    | A value that can change / one that can't.                                                                         |
| `func`                           | A function: a named block of code you can run.                                                                    |
| `static let shared = …`          | A single shared copy that the whole app uses, e.g. `HyperKeyEngine.shared`.                                       |
| `@Observable`                    | "Tell the screen when I change." Flip `isEnabled` in code, and every switch showing it updates by itself.         |
| `@Bindable`, `$engine.isEnabled` | Connects a switch on screen to a value, in both directions.                                                       |
| `@State`                         | A value that belongs to one piece of the screen, like the Open at Login switch.                                   |
| `didSet { … }`                   | Code that runs every time a value changes. Hyperkey uses it to save settings.                                     |
| `UserDefaults`                   | macOS's simple storage for settings. Hyperkey saves `hyperKeyEnabled` and `triggerKey` there.                     |
| `@MainActor`                     | "Only run this on the main thread," the one that also draws the screen. This keeps things from clashing.          |
| `nonisolated(unsafe) static var` | A value the keyboard hook can read directly. The hook is plain C-style code and can't reach normal Swift objects. |
| `guard … else { return }`        | "If this isn't true, stop here."                                                                                  |
| `try?`                           | "Try this; if it fails, ignore the error."                                                                        |
| `// …` and `/// …`               | Comments for humans. The computer ignores them.                                                                   |

---

## 7. Signing and permissions

macOS only lets an app watch the keyboard after you allow it under **System Settings → Privacy & Security → Accessibility**. It remembers that permission by the app's **code signature**, a stamp that proves which app it is.

Hyperkey is signed with a certificate you made yourself, called **Hyperkey Local**, stored in the Keychain Access app. Every build gets the same stamp, so macOS keeps the permission when you rebuild. If you delete that certificate, builds fail until you make a new one, and macOS asks for permission again.

The app isn't in the App Store, because the App Store's "sandbox" (a locked-down mode) doesn't allow watching the keyboard. `ENABLE_APP_SANDBOX: NO` in `project.yml` turns the sandbox off.

---

## 8. Common changes

**Add another trigger key** (e.g. Left ⌥): in `TriggerKey.swift`, add a `case`, a `name` and a `deviceFlag`. The flags for each key:

| Key     | Flag     |
|---------|----------|
| Left ⌃  | `0x01`   |
| Left ⇧  | `0x02`   |
| Right ⇧ | `0x04`   |
| Left ⌘  | `0x08`   |
| Right ⌘ | `0x10`   |
| Left ⌥  | `0x20`   |
| Right ⌥ | `0x40`   |
| Right ⌃ | `0x2000` |

The picker in Settings lists every case automatically.

**Change the on/off shortcut:** in `HyperKeyEngine.swift`, change `escapeKeyCode` (53 is Esc). To find a key's code, search "macOS virtual key codes".

**Add a new Swift file:** create it in `Hyperkey/` and run `make run`. XcodeGen adds new files to the project for you.

**Try a change:** `make run` to test it, then `make install` when you're happy with it.

---

## 9. When something goes wrong

| Problem                                     | Fix                                                                                                                    |
|---------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| Keys act strangely                          | Press **trigger + Esc** to switch Hyper off. Or quit Hyperkey from the menu bar, or with `pkill Hyperkey` in Terminal. |
| Hyper does nothing                          | Open Settings (open Hyperkey from Spotlight) and check that Accessibility shows "Granted" and Enable is on.            |
| Permission shows granted but nothing works  | In System Settings → Accessibility, remove Hyperkey with **–**, then turn it on again.                                 |
| `xcodegen: command not found`               | Install it: `brew install xcodegen`.                                                                                   |
| Build error mentioning "Hyperkey Local"     | The signing certificate is missing from Keychain Access, so you need to make it again.                                 |
| A new file's code "cannot be found"         | Run `make clean`, then `make run`.                                                                                     |
| Red errors in your editor, but `make` works | The editor checks one file at a time and doesn't see the others. If `make` succeeds, the code is fine.                 |
