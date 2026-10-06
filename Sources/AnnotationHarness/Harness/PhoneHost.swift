#if DEBUG && os(iOS)
	import SwiftUI
	import UIKit

	/// Shows the app in its own iPhone-sized window laid over the stage.
	///
	/// UIKit on purpose: navigation and tab bars take their margins, safe area and metrics from their window,
	/// and UIKit gives no side margins to views away from a window's edges. In a window of its own the app lays
	/// out as on a phone, and its sheets and alerts present inside the phone rather than across the iPad.
	struct PhoneHost<Content: View>: UIViewRepresentable {
		let content: Content
		let device: DeviceProfile
		let frame: CGRect
		let scale: CGFloat
		let isHidden: Bool
		let stage: StageGeometry
		@Environment(\.self) private var environment

		func makeUIView(context: Context) -> PhoneWindowAnchor<EnvironmentPassthrough<Content>> {
			PhoneWindowAnchor()
		}

		func updateUIView(_ anchor: PhoneWindowAnchor<EnvironmentPassthrough<Content>>, context: Context) {
			let root = EnvironmentPassthrough(content: content, device: device, environment: environment, stage: stage)
			anchor.update(root: root, device: device, frame: frame, scale: scale, isHidden: isHidden, stage: stage)
		}

		static func dismantleUIView(_ anchor: PhoneWindowAnchor<EnvironmentPassthrough<Content>>, coordinator: ()) {
			anchor.tearDown()
		}
	}

	/// Re-applies the outer environment inside the phone window, which doesn't inherit it,
	/// reports the named screen back out (preferences don't cross windows either) and draws the fake status bar.
	struct EnvironmentPassthrough<Content: View>: View {
		let content: Content
		let device: DeviceProfile
		let environment: EnvironmentValues
		let stage: StageGeometry

		var body: some View {
			content
				// The innermost environment value wins, so the phone's size classes go inside the passed-through ones.
				.environment(\.horizontalSizeClass, .compact)
				.environment(\.verticalSizeClass, .regular)
				.environment(\.self, environment)
				.onPreferenceChange(ScreenNameKey.self) { [stage] name in
					MainActor.assumeIsolated { stage.screenName = name }
				}
				.overlay(alignment: .top) {
					FakeStatusBarView(device: device)
						.environment(\.self, environment)
						.ignoresSafeArea()
				}
		}
	}
#endif
