# Hyperkey

A small macOS menu bar app that turns one key into a "Hyper" key. While you hold it, every keypress is sent as ⌃⌥⇧⌘ + key, a combo no app uses, so you can bind your own shortcuts to it (for example in the Shortcuts app).

## Use

- **Hold Right ⌘** (or Right ⌥ / Right ⇧, chosen in Settings) to press ⌃⌥⇧⌘.
- **Trigger + Esc** switches Hyper on or off, in case something goes wrong. It also works with Caps Lock remapped to Esc.
- Left ⌘ keeps working as normal.

## Permission

Hyperkey needs **Accessibility** access (System Settings → Privacy & Security → Accessibility) to read and change keypresses. Settings shows whether it's granted and has a button to open that pane. Nothing you type is stored or sent anywhere.

## Hide the menu bar icon

System Settings → Menu Bar, then turn Hyperkey off. To get back to Settings, open Hyperkey again from Spotlight or Finder.

## Start at login

Turn on **Open at Login** in Hyperkey Settings.

## Build

Requires Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and a code-signing certificate named **Hyperkey Local** in the login keychain (a stable signature lets macOS remember the Accessibility permission across builds).

```sh
xcodegen
xcodebuild -project Hyperkey.xcodeproj -scheme Hyperkey -configuration Release -derivedDataPath build build
ditto build/Build/Products/Release/Hyperkey.app /Applications/Hyperkey.app
```
