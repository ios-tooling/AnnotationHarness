import SwiftUI

/// A debug-only harness that runs an iPhone layout at its real point size inside an iPad window,
/// with a Pencil markup tool for screenshots and a per-session report for a coding agent.
///
/// Apply `.annotationHarness()` to the app's root view and launch with `-AnnotationHarness` on an iPad.
/// To send windows to an AnnotationHarness Companion instead, apply `.annotationSender()` and call `sendCurrentWindow()`.
/// In release builds every entry point compiles to a no-op.
public enum AnnotationHarness {
	/// The launch argument that turns the harness on.
	public static let launchArgument = "-AnnotationHarness"

	/// Captures the current window and sends it to an AnnotationHarness Companion, asking which one when several are found.
	/// Call it from the app's own menu command, button or hotkey; the root view needs `.annotationSender()`.
	@MainActor public static func sendCurrentWindow() {
		#if DEBUG
			AnnotationSender.shared.send()
		#endif
	}
}

public extension View {
	/// Hosts this view in the annotation harness when a debug build runs on an iPad with `-AnnotationHarness`.
	func annotationHarness() -> some View {
		#if DEBUG && os(iOS)
			modifier(AnnotationHarnessModifier())
		#else
			self
		#endif
	}

	/// Lets `AnnotationHarness.sendCurrentWindow()` send this view's window: shows the companion picker and the send's status,
	/// and labels captures with the screen named by `.annotationScreen(_:)`. Apply it to the app's root view.
	func annotationSender() -> some View {
		#if DEBUG
			modifier(AnnotationSenderModifier())
		#else
			self
		#endif
	}

	/// Names the screen this view shows, so captures taken while it is visible are labelled in the report.
	func annotationScreen(_ name: String) -> some View {
		#if DEBUG
			preference(key: ScreenNameKey.self, value: name)
		#else
			self
		#endif
	}
}

#if DEBUG
	extension AnnotationHarness {
		static func isRequested(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
			arguments.contains(launchArgument)
		}
	}

	struct ScreenNameKey: PreferenceKey {
		static let defaultValue: String? = nil

		static func reduce(value: inout String?, nextValue: () -> String?) {
			value = nextValue() ?? value
		}
	}
#endif
