# AnnotationHarness

Debug-only SwiftUI package: runs an iPhone layout at real size in an iPad window, with Pencil markup of screenshots and a per-session Markdown report for coding agents. README.md covers usage and the report format.

## Rules

- Everything except the public `View` extensions and `AnnotationHarness.launchArgument` lives inside `#if DEBUG`. The extensions return `self` outside DEBUG. Keep it that way so release builds carry nothing.
- Model and report code (`Model/`, `Report/`) is platform-neutral so `swift test` runs on macOS. UI and capture code (`Harness/`, `Capture/`, `Annotate/`) is `#if DEBUG && os(iOS)`.
- The only UIKit uses are the phone window and its hosting controller (`Harness/PhoneWindowAnchor.swift`), the window snapshot plus accessibility walk and activation (`Capture/`), the PencilKit canvas (`Annotate/PencilCanvas.swift`) and the share sheet (`Report/ReportSharer.swift`). Don't add more.
- The phone window sits above the app's main window, so anything the harness presents from the main window must hide it first (`hidesPhone` in `HarnessScreen`).
- One dependency, Suite: the harness sets `Gestalt.idiomOverride = .phone` while active and reads `Gestalt.deviceIdiom` to decide whether to start. Swift 6, Swift Testing, `@Observable`, files around 100 lines.

## Build & test

```bash
swift test
xcodebuild build -scheme AnnotationHarness -destination 'generic/platform=iOS Simulator'
```
