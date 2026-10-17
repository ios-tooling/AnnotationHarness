#if DEBUG
	import AnnotationCore
	import Foundation

	/// Browses for companions briefly, once per send.
	@MainActor enum CompanionDiscovery {
		/// The companions found within `limit`, returning early once a non-empty list has stopped changing for `settle`.
		static func companions(within limit: Duration = .milliseconds(1500), settle: Duration = .milliseconds(300)) async -> [CompanionBrowser.Companion] {
			let results = Results()
			let browsing = Task { @MainActor in
				for await found in CompanionBrowser.companions() { results.update(found) }
			}
			defer { browsing.cancel() }
			let clock = ContinuousClock()
			let deadline = clock.now + limit
			while clock.now < deadline, !Task.isCancelled, !results.hasSettled(for: settle, at: clock.now) {
				try? await Task.sleep(for: .milliseconds(100))
			}
			return results.found
		}

		/// The latest list the browser reported, and when it last changed.
		@MainActor private final class Results {
			private(set) var found: [CompanionBrowser.Companion] = []
			private var changed: ContinuousClock.Instant?

			func update(_ list: [CompanionBrowser.Companion]) {
				guard list != found else { return }
				found = list
				changed = ContinuousClock().now
			}

			func hasSettled(for settle: Duration, at now: ContinuousClock.Instant) -> Bool {
				guard let changed, !found.isEmpty else { return false }
				return now - changed >= settle
			}
		}
	}
#endif
