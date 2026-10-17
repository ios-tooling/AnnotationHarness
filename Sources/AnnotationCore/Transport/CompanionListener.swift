import Foundation
import Network

/// The companion's side: advertises `_annotharness._tcp` over Bonjour and yields each capture a sender delivers,
/// acking every envelope that decodes. It can be stopped and started again; `envelopes` carries on across restarts.
@MainActor package final class CompanionListener {
	/// Every envelope received while started.
	package let envelopes: AsyncStream<CaptureEnvelope>
	/// The name the service is registered under each time Bonjour registers it, which can differ from `name` (the device's name when that's `nil`).
	package let advertisedNames: AsyncStream<String>
	/// The advertised service name; `nil` advertises under the device's name.
	package let name: String?
	private let continuation: AsyncStream<CaptureEnvelope>.Continuation
	private let namesContinuation: AsyncStream<String>.Continuation
	private var listener: NWListener?

	/// The port it listens on while started.
	package var port: NWEndpoint.Port? { listener?.port }

	package init(name: String? = nil) {
		self.name = name
		(envelopes, continuation) = AsyncStream.makeStream()
		(advertisedNames, namesContinuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
	}

	deinit {
		continuation.finish()
		namesContinuation.finish()
	}

	/// Starts listening and advertising, and returns once the listener is ready. Does nothing if it's already started.
	package func start() async throws {
		guard listener == nil else { return }
		let listener = try Self.makeListener(name: name, continuation: continuation, names: namesContinuation)
		self.listener = listener
		do {
			try await listener.open()
		} catch {
			listener.cancel()
			if self.listener === listener { self.listener = nil }
			throw error
		}
	}

	/// Stops listening and advertising.
	package func stop() {
		listener?.cancel()
		listener = nil
	}

	/// Built outside the main actor, so Network.framework's callbacks on its own queue aren't main-actor closures.
	private nonisolated static func makeListener(name: String?, continuation: AsyncStream<CaptureEnvelope>.Continuation, names: AsyncStream<String>.Continuation) throws -> NWListener {
		let listener = try NWListener(using: .tcp)
		listener.service = NWListener.Service(name: name, type: CompanionWire.serviceType)
		listener.serviceRegistrationUpdateHandler = { change in
			if case .add(.service(let name, _, _, _)) = change { names.yield(name) }
		}
		listener.newConnectionHandler = { connection in
			Task { await receive(on: connection, into: continuation) }
		}
		return listener
	}

	/// One envelope per connection: read it, hand it on, ack it, close. A sender that stalls is dropped after the timeout.
	private nonisolated static func receive(on connection: NWConnection, into continuation: AsyncStream<CaptureEnvelope>.Continuation) async {
		try? await connection.exchange(timeout: .seconds(30)) {
			try await connection.open()
			let envelope = try await connection.readEnvelope()
			continuation.yield(envelope)
			try await connection.write(Data([CompanionWire.ack]))
		}
	}
}

extension NWListener {
	/// Starts the listener and returns once it's ready; throws if it fails first.
	func open() async throws {
		let states = AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
			stateUpdateHandler = { continuation.yield($0) }
		}
		start(queue: companionQueue)
		for await state in states {
			switch state {
			case .ready: return
			case .failed(let error), .waiting(let error): throw error
			case .cancelled: throw CompanionTransportError.closed
			default: continue
			}
		}
		throw CompanionTransportError.closed
	}
}
