import Foundation
import Network

/// Sends one capture to a companion: one envelope per connection, finished by the companion's ack.
package enum CompanionClient {
	/// Connects to `endpoint`, writes the encoded envelope and waits for the ack; throws `CompanionTransportError.timedOut` after `timeout`.
	package static func send(_ envelope: CaptureEnvelope, to endpoint: NWEndpoint, timeout: Duration = .seconds(10)) async throws {
		let bytes = try envelope.encoded()
		let connection = NWConnection(to: endpoint, using: .tcp)
		try await connection.exchange(timeout: timeout) {
			try await connection.open()
			try await connection.write(bytes)
			let reply = try await connection.read(exactly: 1)
			guard reply.first == CompanionWire.ack else { throw CompanionTransportError.badAck }
		}
	}
}
