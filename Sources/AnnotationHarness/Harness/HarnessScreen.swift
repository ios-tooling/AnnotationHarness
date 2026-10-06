#if DEBUG && os(iOS)
	import Suite
	import SwiftUI

	/// Turns the harness on for a debug build on an iPad launched with `-AnnotationHarness`; otherwise passes the content through.
	/// While it's on, Suite's `Gestalt.isOnIPhone` reports true (and `isOnIPad` false), so idiom checks see the phone being imitated.
	struct AnnotationHarnessModifier: ViewModifier {
		@State private var isActive = AnnotationHarnessModifier.activate()

		private static func activate() -> Bool {
			guard AnnotationHarness.isRequested(), Gestalt.deviceIdiom == .pad else { return false }
			Gestalt.idiomOverride = .phone
			return true
		}

		func body(content: Content) -> some View {
			if isActive {
				HarnessScreen(content: content)
			} else {
				content
			}
		}
	}

	/// The app at iPhone size on a stage, with the capture tools in an inspector beside it.
	struct HarnessScreen<Content: View>: View {
		let content: Content
		@State private var session: HarnessSession?
		@State private var stage = StageGeometry()
		@State private var draft: CaptureDraft?
		@State private var showsInspector = true
		@State private var inspectorIsPresenting = false

		var body: some View {
			DeviceStageView(device: session?.device ?? .standard, content: content, stage: stage, hidesPhone: draft != nil || inspectorIsPresenting)
				.inspector(isPresented: $showsInspector) {
					if let session {
						HarnessInspectorView(session: session, isPresenting: $inspectorIsPresenting, capture: capture, share: share, startNewSession: startNewSession)
					} else {
						ProgressView()
					}
				}
				.fullScreenCover(item: $draft) { draft in
					if let session { AnnotationScreen(draft: draft, session: session) }
				}
				.task {
					AccessibilityActivation.activate()
					if session == nil { session = .resumeOrStart() }
				}
		}

		private func capture() {
			guard let window = stage.window else { return }
			draft = CaptureSnapshotter.draft(of: window, screenName: stage.screenName)
		}

		/// The share sheet presents from the main window, which the phone window sits above, so the phone hides until it closes.
		private func share(from rect: CGRect) {
			guard let session, let window = stage.hostWindow else { return }
			inspectorIsPresenting = true
			ReportSharer.share(session.archive, from: rect, in: window) { inspectorIsPresenting = false }
		}

		private func startNewSession() {
			session = .start(deviceID: session?.deviceID ?? DeviceProfile.standard.id)
		}
	}

	/// The phone window, the app's own window beneath it and the screen being shown, kept up to date by the stage.
	@MainActor final class StageGeometry {
		weak var window: UIWindow?
		weak var hostWindow: UIWindow?
		var screenName: String?
	}
#endif
