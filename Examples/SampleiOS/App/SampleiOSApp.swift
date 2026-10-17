import AnnotationHarness
import SwiftUI

/// An iPhone/iPad host for checking AnnotationHarness's sender, by network or through the pasteboard on the same device.
@main struct SampleiOSApp: App {
	var body: some Scene {
		WindowGroup {
			RootScreen()
				.annotationSender()
		}
	}
}

/// The sample's screens, by the name `-SendOnLaunch` takes.
enum SampleScreen: String, Hashable {
	case home, settings
}

struct RootScreen: View {
	@State private var path: [SampleScreen] = []

	var body: some View {
		NavigationStack(path: $path) {
			HomeScreen()
				.navigationDestination(for: SampleScreen.self) { _ in SettingsScreen() }
		}
		.task { await sendOnLaunch() }
	}

	/// Test hook: `-SendOnLaunch settings` (or `home`) shows that screen and sends it to the companion about 2 s after launch.
	private func sendOnLaunch() async {
		guard let name = UserDefaults.standard.string(forKey: "SendOnLaunch"), let screen = SampleScreen(rawValue: name) else { return }
		if screen != .home { path = [screen] }
		try? await Task.sleep(for: .seconds(2))
		AnnotationHarness.sendCurrentWindow()
	}
}
