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

Launch a debug build on an iPad with the `-AnnotationHarness` argument (Xcode: Scheme › Run › Arguments; simulator: `xcrun simctl launch <udid> <bundle-id> -AnnotationHarness`). Without the argument, on an iPhone or in a release build, the app runs untouched; a debug build on an iPad without it prints a one-line note to the console saying how to turn it on. Adding the argument to the app's shared scheme, ticked, makes every Xcode run on an iPad use the harness. Everything in the package compiles to a no-op outside `DEBUG`, so the `#if DEBUG` at the call site is a second guard, not the only one.

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

## Sending to the companion

A Mac, iPhone or iPad app can also send its current window to an iPad running **AnnotationHarness Companion**, which collects the captures per app for markup and reporting there.

- `.annotationSender()` on the root view shows the companion picker and a brief status ("Sent to Desk iPad", "No AnnotationHarness Companion found", or the error), and labels captures with `.annotationScreen(_:)` names.
- `AnnotationHarness.sendCurrentWindow()` captures the current window (on a Mac, the key window with its title bar and toolbar) and its accessibility elements, then sends it. Call it from your own menu command, button or hotkey.

Companions are found over Bonjour. One is used straight away; with several you're asked once, and that choice holds for the rest of the run. Both are no-ops outside `DEBUG`.

```swift
WindowGroup {
	RootScreen()
		#if DEBUG
			.annotationSender()
		#endif
}
.commands {
	#if DEBUG
		CommandMenu("Debug") {
			Button("Send Window to Companion") { AnnotationHarness.sendCurrentWindow() }
				.keyboardShortcut("s", modifiers: [.command, .control])
		}
	#endif
}
```

With the iPad harness, apply `.annotationSender()` before `.annotationHarness()` so the picker and status show inside the phone window, which sits above the app's own; the phone window is what's sent.

The host's Info.plist (a debug-only xcconfig or Info.plist is a good place) needs:

- `NSLocalNetworkUsageDescription`: why the app uses the local network, e.g. "Sends screenshots to AnnotationHarness Companion."
- `NSBonjourServices`: `_annotharness._tcp`
- iOS only, `LSApplicationQueriesSchemes`: `annotationharness`
- A sandboxed Mac app also needs the `com.apple.security.network.client` entitlement.

**Same device:** when no companion is on the network and the companion is installed on the same iPhone or iPad, the capture goes through the clipboard instead: it's put on the general pasteboard (replacing whatever you had copied) and the companion is opened to pick it up. This needs the `LSApplicationQueriesSchemes` entry above.

## Limits

- `UIDevice.current.userInterfaceIdiom` still says `.pad`, and the keyboard is the iPad's. Check the idiom through Suite's `Gestalt.isOnIPhone` / `isOnIPad` instead: the harness sets `Gestalt.idiomOverride = .phone` while it runs (`Gestalt.deviceIdiom` keeps the hardware's). It does so when the root view first appears, so a check made earlier, in the app's `init`, still sees the iPad.
- UIKit is used where SwiftUI has no equivalent: the phone window and its hosting controller (`PhoneWindowAnchor`, which is what gives the app phone margins, safe area and presentations), the window snapshot (`drawHierarchy`), the Pencil canvas (`PKCanvasView`) and the share sheet (`ReportSharer`, because `ShareLink` can't tell the harness when to hide the phone).
- Capturing the accessibility tree switches on the app's accessibility runtime through a private libAccessibility call, the way snapshot-testing tools do. It is compiled only in DEBUG. On the Mac the sender reads the window's elements through the public accessibility client API (`AXUIElement`) on the app's own process. That needs no permission, and it makes SwiftUI build its accessibility tree, which it otherwise does only once an outside client asks.
