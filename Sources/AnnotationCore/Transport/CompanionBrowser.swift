import Foundation
import Network

/// Finds companions advertising on the local network over Bonjour.
package enum CompanionBrowser {
	/// A companion that was found, under the name it advertises.
	package struct Companion: Sendable, Hashable {
		package let name: String
		package let endpoint: NWEndpoint
	}

	/// The companions on the network, sent again whenever the list changes. Browsing stops when the stream's consumer goes away.
	package static func companions() -> AsyncStream<[Companion]> {
		AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
			let browser = NWBrowser(for: .bonjour(type: CompanionWire.serviceType, domain: nil), using: .tcp)
			browser.browseResultsChangedHandler = { results, _ in
				continuation.yield(results.compactMap(companion(for:)).sorted { $0.name < $1.name })
			}
			browser.stateUpdateHandler = { state in
				switch state {
				case .failed, .cancelled: continuation.finish()
				default: break
				}
			}
			continuation.onTermination = { _ in browser.cancel() }
			browser.start(queue: companionQueue)
		}
	}

	private static func companion(for result: NWBrowser.Result) -> Companion? {
		guard case .service(let name, _, _, _) = result.endpoint else { return nil }
		return Companion(name: name, endpoint: result.endpoint)
	}
}
