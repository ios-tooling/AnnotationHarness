#if DEBUG
	import SwiftUI

	/// Shows the sender's companion picker and status in the active window, and tells the sender which screen that window shows.
	/// Every window with the modifier shares the one sender, so only the window that appears active shows them.
	struct AnnotationSenderModifier: ViewModifier {
		@State private var screenName: String?
		@Environment(\.appearsActive) private var appearsActive
		@Environment(\.openURL) private var openURL
		private let sender = AnnotationSender.shared

		func body(content: Content) -> some View {
			content
				.onPreferenceChange(ScreenNameKey.self) { [$screenName] name in
					MainActor.assumeIsolated { $screenName.wrappedValue = name }
				}
				.onChange(of: screenName, initial: true) { publishScreenName() }
				.onChange(of: appearsActive) { publishScreenName() }
				.onChange(of: sender.urlToOpen) { openPendingURL() }
				.confirmationDialog("Send to which companion?", isPresented: picksCompanion, titleVisibility: .visible, presenting: sender.pick) { pick in
					ForEach(pick.companions, id: \.self) { companion in
						Button(companion.name) { sender.send(pick.envelope, to: companion) }
					}
					Button("Cancel", role: .cancel) {}
				}
				.overlay(alignment: .bottom) {
					if appearsActive, let status = sender.status {
						SenderStatusView(message: status)
					}
				}
				.animation(.default, value: sender.status)
				.task {
					#if os(iOS)
						// SwiftUI builds its accessibility tree only once something asks, so switch it on before the first capture.
						AccessibilityActivation.activate()
					#endif
				}
		}

		private var picksCompanion: Binding<Bool> {
			Binding {
				appearsActive && sender.pick != nil
			} set: { isPresented in
				if !isPresented { sender.pick = nil }
			}
		}

		private func publishScreenName() {
			if appearsActive { sender.screenName = screenName }
		}

		/// Opens the companion after a same-device send. Read from the sender, so only one window opens it.
		private func openPendingURL() {
			guard appearsActive, let url = sender.urlToOpen else { return }
			sender.urlToOpen = nil
			openURL(url) { accepted in
				if !accepted { sender.show("Couldn't open AnnotationHarness Companion") }
			}
		}
	}

	/// The sender's outcome, floating briefly over the bottom of the window.
	struct SenderStatusView: View {
		let message: String

		var body: some View {
			Text(message)
				.font(.callout)
				.padding()
				.background(.regularMaterial, in: .capsule)
				.padding()
				.transition(.opacity)
				.allowsHitTesting(false)
		}
	}
#endif
