# Companion app plan

A Mac, iPhone or iPad app that includes AnnotationHarness can send its current window to an iPad running **AnnotationHarness Companion**. The companion holds the incoming captures grouped by app, you mark them up with the Pencil, and you share each app's report the way the in-app harness does today.

## Decisions so far

- **Report delivery:** the companion shares the finished report (zip) from the share sheet, as the in-app harness does. Nothing is sent back to the source app.
- **Grouping:** captures waiting to be annotated are kept per source app, and the user switches between apps. Each app gets its own session and report.
- **Format:** unchanged (`report.md`, `session.json`, `captures/*.png`). Markdown + PNG is what coding agents read directly; RTFD is a package of RTF and attachments, which agents can't read well, and it would add nothing for a person.
- **Discovery:** automatic over Bonjour. If more than one companion is found, the sender asks once per run of the app and then remembers that choice for the rest of the run.
- **Distribution:** Xcode or TestFlight, never the App Store.

## Pieces

### 1. Shared core: package split and wire format (first; everything else depends on it)

Split the single target:

| Target | Platforms | Gated | Contents |
| --- | --- | --- | --- |
| `AnnotationCore` | iOS, macOS | no | `Model/`, `Report/` (writer, archive), wire format, Bonjour client and server |
| `AnnotationUI` | iOS | no | `Annotate/` (screen, Pencil canvas, compositor), `ReportSharer` |
| `AnnotationHarness` | iOS, macOS | `#if DEBUG` | the in-app iPad harness, the senders, the public `View` extensions |
| `AnnotationCompanion` | iOS | no | the companion's feature code; the app target only hosts it |

**Rule change:** today everything in the package is DEBUG-only. The companion ships as a Release/TestFlight build, so the core and UI targets can't be gated. Host apps still link only `AnnotationHarness`, which stays gated. In a host's Release build nothing references the core targets, so dead-stripping drops them. The private accessibility call stays in the gated target. CLAUDE.md's rules get updated to match.

Changes in the core:
- `SessionManifest` gets a **source** (app name, bundle ID, version, build, platform) and a **layout** (`harness(deviceID)`, `macWindow(size)` or `screen(device model, size)`) in place of reading `Bundle.main` and taking a bare `deviceID`. Old `session.json` files still decode, falling back to `harness(deviceID)`.
- `ReportWriter`'s "Layout" line and frame explanation follow the layout ("points from the top-left of the window" for a Mac window).
- **Wire format:** a `CaptureEnvelope` (source, layout, screen name, date, accessibility nodes, image scale), sent over a TCP `NWConnection` as a length-prefixed JSON header followed by the length-prefixed PNG. One envelope per connection, and the companion replies with an ack byte, so the sender knows it arrived. The same encoded bytes are what goes on the pasteboard for same-device sends.
- **Transport:** the companion advertises `_annotharness._tcp` through `NWListener`, named after the iPad. Senders find it with `NWBrowser`. Network.framework with Bonjour is the current standard for this; MultipeerConnectivity is the older option.
- Tests: envelope round trip and framing, decoding old manifests, the report's layout lines.

### 2. Companion app (after 1; can run alongside 3 and 4)

- `Apps/Companion/`: an Xcode project with a thin app target, `Version.xcconfig`, `NSBonjourServices` and a local-network usage string. It depends on `AnnotationCompanion`.
- **Receiver:** an `@Observable` model that runs the listener whenever the app is in the foreground and writes each envelope into an inbox on disk: `Documents/Inbox/<bundleID>/<uuid>/`.
- **Screens:** a `NavigationSplitView` with source apps in the sidebar, each showing its waiting captures and saved captures. Tapping a waiting capture opens the shared `AnnotationScreen`, and saving moves it into that app's `HarnessSession` (`Documents/Sessions/<bundleID>/<session>/`). Each app has Share Report and New Session.
- Done when: it builds for iPad and its model tests pass (inbox → session move, grouping). End-to-end checking happens in step 5.

### 3. Mac sender (after 1)

- Public API: `AnnotationHarness.sendKeyWindow()`, which the host calls from its own menu command or hotkey, plus a `.annotationSender()` modifier on the root view. The modifier shows the target picker (a SwiftUI `confirmationDialog`) and the sent/failed status. Outside DEBUG both are no-ops.
- **Capture:** `NSView.cacheDisplay` on the window's frame view, which includes the title bar and toolbar. It needs no Screen Recording permission. It can miss Metal, video and some layer content; ScreenCaptureKit is a later option if that matters.
- **Accessibility:** a walk of the window's `NSAccessibility` children. Frames are converted to points from the window's top-left. It's the app's own process, so no private API is needed.
- The host app needs `NSBonjourServices` and a local-network usage string in Info.plist. The README documents this, with a debug-only xcconfig snippet.
- This adds AppKit to the allowed list (window snapshot, accessibility walk), recorded in CLAUDE.md.

### 4. iPhone/iPad sender (after 1)

- The same API on iOS. When a companion is on the network (for example an iPhone app sending to an iPad), it uses the same Bonjour path as the Mac.
- **Same device: pasteboard + URL scheme.** When the companion is in the background, iOS suspends it, so loopback networking can't be relied on. Instead, the sender puts the encoded envelope on the general pasteboard under a custom type (`com.annotationharness.envelope`) and opens `annotationharness://receive`. The companion registers that scheme, reads the envelope off the pasteboard, adds it to the inbox and clears the pasteboard. This overwrites the user's clipboard. To avoid a paste prompt on every send, the companion should be set to Settings › Paste from Other Apps › Allow once; it explains this the first time.
- The sender picks the path: it uses Bonjour when a companion is found on the network, and otherwise uses the same-device path if `annotationharness://` can be opened. That needs `LSApplicationQueriesSchemes` in the host's Info.plist.

### 5. Integration check (last)

- A small example Mac app and an iPad simulator on the same Mac. Bonjour works between them, since the simulator shares the Mac's network. Send two windows from two apps, check the companion groups them, annotate them, and share each report. Screenshots of each step.
- On a single iPad simulator: send from a sample iOS app to the companion by the same-device path.

## Status

Steps 1–5 are done (2026-10-16). Sample host apps are in `Examples/`. The same-device path, the picker and the reports were all checked on simulators. Still open:
- A live Mac → iPad send wasn't run, because the Mac's Local Network prompt for SampleMac was unanswered. The bytes SampleMac produced were relayed to the companion and worked.
- Fixed since: Mac captures now list SwiftUI accessibility elements, read through `AXUIElement` on the app's own pid.

## Order

1 → (2, 3, 4 in parallel; they touch separate targets) → 5. The `.pbxproj` exists only in step 2.
