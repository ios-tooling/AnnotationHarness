#if DEBUG
	import AnnotationCore
	import Foundation
	import Network
	import Observation

	/// Bridges `AnnotationHarness.sendCurrentWindow()` and the `.annotationSender()` modifier: captures the window,
	/// picks a companion and sends to it, and holds the picker and status the modifier shows.
	@MainActor @Observable final class AnnotationSender {
		static let shared = AnnotationSender()

		/// A capture already taken, waiting on the picker to say which companion gets it.
		struct Pick {
			let envelope: CaptureEnvelope
			let companions: [CompanionBrowser.Companion]
		}

		/// The screen named with `.annotationScreen(_:)` in the active window.
		var screenName: String?
		/// Set while the companion picker should show.
		var pick: Pick?
		/// A same-device send's URL, for the modifier to open with SwiftUI's `openURL`.
		var urlToOpen: URL?
		/// The latest outcome, shown for a few seconds.
		private(set) var status: String?
		/// The companion picked earlier in this run; kept in memory only.
		private(set) var remembered: String?
		private var isSending = false
		private var statusClearing: Task<Void, Never>?

		/// Captures the current window now, then finds a companion and sends it in the background.
		func send() {
			guard !isSending else { return }
			guard let envelope = WindowCapture.envelope(screenName: screenName) else { return show("No window to send") }
			isSending = true
			Task {
				await route(envelope)
				isSending = false
			}
		}

		/// Sends a capture to the companion picked for it, and remembers that choice for the rest of the run.
		func send(_ envelope: CaptureEnvelope, to companion: CompanionBrowser.Companion) {
			remembered = companion.name
			Task { await deliver(envelope, to: companion) }
		}

		private func route(_ envelope: CaptureEnvelope) async {
			let found = await CompanionDiscovery.companions()
			switch SendTarget.choose(found: found.map(\.name), remembered: remembered, sameDeviceAvailable: found.isEmpty && WindowCapture.sameDeviceAvailable) {
			case .companion(let name):
				guard let companion = found.first(where: { $0.name == name }) else { return }
				await deliver(envelope, to: companion)
			case .ask:
				pick = Pick(envelope: envelope, companions: found)
			case .sameDevice:
				sendOnThisDevice(envelope)
			case .nothingFound:
				show("No AnnotationHarness Companion found")
			}
		}

		func deliver(_ envelope: CaptureEnvelope, to companion: CompanionBrowser.Companion) async {
			do {
				try await CompanionClient.send(envelope, to: companion.endpoint)
				show("Sent to \(companion.name)")
			} catch {
				show("Couldn't send to \(companion.name): \(Self.reason(for: error))")
			}
		}

		private func sendOnThisDevice(_ envelope: CaptureEnvelope) {
			#if os(iOS)
				do {
					try SameDeviceSend.place(envelope)
					urlToOpen = CompanionWire.receiveURL
				} catch {
					show("Couldn't send: \(Self.reason(for: error))")
				}
			#endif
		}

		/// Shows `message` for a few seconds, replacing any earlier one.
		func show(_ message: String) {
			status = message
			statusClearing?.cancel()
			statusClearing = Task {
				try? await Task.sleep(for: .seconds(3))
				if !Task.isCancelled { status = nil }
			}
		}

		private static func reason(for error: any Error) -> String {
			switch error {
			case CompanionTransportError.timedOut: "it didn't answer in time"
			case CompanionTransportError.closed: "the connection closed early"
			case CompanionTransportError.badAck: "it sent an unexpected reply"
			case let error as NWError: error.debugDescription
			default: error.localizedDescription
			}
		}
	}
#endif
