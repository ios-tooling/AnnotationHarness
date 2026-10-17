import AnnotationHarness
import SwiftUI

struct HomeScreen: View {
	@State private var name = ""

	var body: some View {
		Form {
			Section("Profile") {
				TextField("Your name", text: $name)
				NavigationLink("Settings", value: SampleScreen.settings)
			}
			Section {
				SendButton()
			}
		}
		.navigationTitle("Home")
		.annotationScreen("Home")
	}
}

struct SettingsScreen: View {
	@State private var notifications = true
	@State private var volume = 0.5

	var body: some View {
		Form {
			Toggle("Notifications", isOn: $notifications)
			Slider(value: $volume) { Text("Volume") }
			Section {
				SendButton()
			}
		}
		.navigationTitle("Settings")
		.annotationScreen("Settings")
	}
}

struct SendButton: View {
	var body: some View {
		Button("Send to Companion", systemImage: "paperplane") { AnnotationHarness.sendCurrentWindow() }
	}
}
