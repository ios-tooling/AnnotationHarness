import AnnotationHarness
import SwiftUI

/// A Mac host for checking AnnotationHarness's sender: two kinds of windows, each sendable to the companion.
@main struct SampleMacApp: App {
	var body: some Scene {
		WindowGroup("Library", id: SampleWindow.library.rawValue) {
			LibraryScreen()
				.annotationSender()
				.sendsOnLaunch()
		}
		.defaultSize(width: 860, height: 560)
		.commands {
			CommandMenu("Debug") {
				Button("Send Window to iPad") { AnnotationHarness.sendCurrentWindow() }
					.keyboardShortcut("s", modifiers: [.control, .option, .command])
			}
		}

		Window("Inspector", id: SampleWindow.inspector.rawValue) {
			InspectorScreen()
				.annotationSender()
		}
		.defaultSize(width: 320, height: 440)
	}
}

/// The sample's window scenes, by the ID `-SendOnLaunch` takes.
enum SampleWindow: String {
	case library, inspector
}
