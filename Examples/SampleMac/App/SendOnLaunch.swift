import AnnotationHarness
import SwiftUI

extension View {
	/// Test hook: `-SendOnLaunch library,inspector` opens each listed window in turn and sends it to the companion,
	/// starting about 2 s after launch. The Library window is the one already open, so it is only sent.
	func sendsOnLaunch() -> some View {
		modifier(SendOnLaunchModifier())
	}
}

private struct SendOnLaunchModifier: ViewModifier {
	@Environment(\.openWindow) private var openWindow
	@MainActor private static var hasRun = false

	func body(content: Content) -> some View {
		content.task {
			guard !Self.hasRun, let list = UserDefaults.standard.string(forKey: "SendOnLaunch") else { return }
			Self.hasRun = true
			for id in list.split(separator: ",").map(String.init) {
				if id != SampleWindow.library.rawValue { openWindow(id: id) }
				// Launched from a script, the app may not be active, and then no window is key.
				NSApp.activate()
				try? await Task.sleep(for: .seconds(2))
				AnnotationHarness.sendCurrentWindow()
				try? await Task.sleep(for: .seconds(3))
			}
		}
	}
}
