# AnnotationHarness

Debug-only SwiftUI package: runs an iPhone layout at real size in an iPad window, with Pencil markup of screenshots and a per-session Markdown report for coding agents. A companion iPad app (in progress, see docs/companion-plan.md) receives captures from Mac and iOS host apps. README.md covers usage and the report format.

## Targets

- `AnnotationCore` (iOS + macOS, not gated): `Model/`, `Report/`, `Wire/` (envelope framing, shared constants), `Transport/` (Bonjour listener, browser, client). Platform-neutral so `swift test` runs on macOS.
- `AnnotationUI` (`#if os(iOS)`, not gated): the Pencil markup screen and share sheet, shared by the harness and the companion.
- `AnnotationHarness` (the only product host apps link): everything except the public `View` extensions and `AnnotationHarness.launchArgument` lives inside `#if DEBUG`, and the extensions return `self` outside DEBUG. Core and UI are un-gated only so the companion can ship in Release. Host apps never reference them, so they are dead-stripped. Keep private API (the accessibility activation) in this target.
- Cross-target symbols use `package` access, not `public`.

## Rules

- UI and capture code in the harness (`Harness/`, `Capture/`) is `#if DEBUG && os(iOS)`.
- The only UIKit uses are the phone window and its hosting controller (`Harness/PhoneWindowAnchor.swift`), the window snapshot plus accessibility walk and activation (`Capture/`), the PencilKit canvas (`AnnotationUI/Annotate/PencilCanvas.swift`) the share sheet (`AnnotationUI/Report/ReportSharer.swift`), the iOS sender's window lookup, pasteboard and `canOpenURL` (`Sender/WindowCapture+iOS.swift`, `Sender/SameDeviceSend.swift`), and the companion's pasteboard read (`CompanionStore+Pasteboard.swift`). The only AppKit uses are the Mac sender's window snapshot and accessibility walk (`Sender/WindowCapture+macOS.swift`, `Sender/MacAccessibilityReader.swift`). Don't add more.
- `AnnotationCompanion` is the companion app's feature code; `Apps/Companion/` holds only the app shell, generated from `project.yml` with XcodeGen.
- Host apps apply `.annotationSender()` inside `.annotationHarness()`, so its picker shows in the phone window rather than behind it.
- Network.framework callbacks run on the one `companionQueue` and are bridged to async/await; that's the only dispatch queue allowed.
- The phone window sits above the app's main window, so anything the harness presents from the main window must hide it first (`hidesPhone` in `HarnessScreen`).
- One dependency, Suite, used only by `AnnotationHarness`: the harness sets `Gestalt.idiomOverride = .phone` while active and reads `Gestalt.deviceIdiom` to decide whether to start. Swift 6, Swift Testing, `@Observable`, files around 100 lines.

## Build & test

```bash
swift test
xcodebuild build -scheme AnnotationHarness -destination 'generic/platform=iOS Simulator'
xcodebuild build -scheme AnnotationHarness -destination 'generic/platform=macOS'
xcodebuild build -project "Apps/Companion/AnnotationHarness Companion.xcodeproj" -scheme "AnnotationHarness Companion" -destination 'generic/platform=iOS Simulator'
```

After editing `Apps/Companion/project.yml`, regenerate with `cd Apps/Companion && xcodegen`.
