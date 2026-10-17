import AnnotationCore
import Foundation

extension CompanionStore {
	/// Advertises the companion and files what senders deliver; called when the scene becomes active.
	/// If the listener can't start, it tries again every few seconds until it does or `stopListening()` is called.
	package func startListening() {
		startReceiving()
		listening?.cancel()
		listening = Task { await keepListening() }
	}

	/// Stops advertising; called when the scene goes to the background, where iOS suspends the app anyway.
	package func stopListening() {
		listening?.cancel()
		listening = nil
		listener.stop()
	}

	private func keepListening() async {
		while !Task.isCancelled {
			do {
				try await listener.start()
				problem = nil
				return
			} catch {
				problem = "Couldn't start listening for captures: \(error.localizedDescription)"
				try? await Task.sleep(for: .seconds(3))
			}
		}
	}

	/// Reads the listener's streams for as long as the store lives. They carry on across the listener's restarts,
	/// and are never iterated from a task that gets cancelled, since that would end them for good.
	private func startReceiving() {
		guard receiving.isEmpty else { return }
		let envelopes = listener.envelopes
		let names = listener.advertisedNames
		receiving = [
			Task { [weak self] in
				for await envelope in envelopes { self?.file(envelope) }
			},
			Task { [weak self] in
				for await name in names { self?.advertisedName = name }
			},
		]
	}

	private func file(_ envelope: CaptureEnvelope) {
		do {
			try receive(envelope)
			problem = nil
		} catch {
			problem = "Couldn't save a capture from \(envelope.source.name): \(error.localizedDescription)"
		}
	}
}
