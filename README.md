# AnnotationHarness

A debug-only harness for reviewing an iPhone app on an iPad. The app runs at real iPhone point size inside the iPad window. You capture a screen, mark it up with the Pencil, add a note, and export the session as one report for a coding agent.

## Setup

```swift
import SwiftUI
#if DEBUG
	import AnnotationHarness
#endif

WindowGroup {
	RootScreen()
		#if DEBUG
			.annotationHarness()
		#endif
}
```

Launch a debug build on an iPad with the `-AnnotationHarness` argument (Xcode: Scheme › Run › Arguments; simulator: `xcrun simctl launch <udid> <bundle-id> -AnnotationHarness`). Without the argument, on an iPhone or in a release build, the app runs untouched. Everything in the package compiles to a no-op outside `DEBUG`, so the `#if DEBUG` at the call site is a second guard, not the only one.

Optionally name screens so captures are labelled: `.annotationScreen("Reviews")`. The deepest named view on screen wins, and you can edit the name before saving.

## Using it

- **Stage:** the app runs in its own iPhone-sized window over the stage, with the chosen iPhone's safe area, compact size classes and a drawn status bar (time, Dynamic Island or notch, signal, Wi-Fi, battery). Navigation bars, margins and the app's own sheets, alerts and menus behave as on a phone and stay inside the frame. It shows at 1:1 when it fits and is scaled down only when the window is too small (for example, landscape on an 11-inch iPad).
- **Capture Screen** (inspector) snapshots the iPhone screen at full resolution and records the accessibility elements on it. Mark it up with the Pencil (finger works too), name the screen, add a note, then Save.
- **Share Report** zips the session folder and opens the share sheet. The phone hides while the sheet (or the New Session dialog) is up, since it sits above them.
- **New Session** starts a fresh report. Old sessions stay in `Documents/AnnotationHarness/`.

## The report

```
<App>-annotations-<session>.zip
  report.md          one section per capture: annotated image, link to the original, note, accessibility elements
  session.json       the same data for tools
  captures/001-annotated.png
  captures/001-original.png
```

Accessibility frames are in points from the top-left of the iPhone screen, so they line up with the original PNG at its point size.

## Limits

- `UIDevice.current.userInterfaceIdiom` still says `.pad`, and the keyboard is the iPad's. Check the idiom through Suite's `Gestalt.isOnIPhone` / `isOnIPad` instead: the harness sets `Gestalt.idiomOverride = .phone` while it runs (`Gestalt.deviceIdiom` keeps the hardware's). It does so when the root view first appears, so a check made earlier, in the app's `init`, still sees the iPad.
- UIKit is used where SwiftUI has no equivalent: the phone window and its hosting controller (`PhoneWindowAnchor`, which is what gives the app phone margins, safe area and presentations), the window snapshot (`drawHierarchy`), the Pencil canvas (`PKCanvasView`) and the share sheet (`ReportSharer`, because `ShareLink` can't tell the harness when to hide the phone).
- Capturing the accessibility tree switches on the app's accessibility runtime through a private libAccessibility call, the way snapshot-testing tools do. It is compiled only in DEBUG.
