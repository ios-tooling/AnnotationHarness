import Foundation
import Network
import Testing
@testable import AnnotationCore

@MainActor struct CompanionLoopbackTests {
	@Test("A listener on this machine receives what the client sends and acks it", .timeLimit(.minutes(1)))
	func loopback() async throws {
		let listener = CompanionListener(name: "AnnotationHarnessTests-\(UUID().uuidString.prefix(8))")
		do {
			try await listener.start()
		} catch {
			try Test.cancel("Skipped: networking isn't available in this test environment (\(error))")
		}
		defer { listener.stop() }
		let port = try #require(listener.port)

		// Straight to the port rather than through Bonjour, which can be slow or blocked in test runs.
		try await CompanionClient.send(.sample, to: .hostPort(host: "127.0.0.1", port: port), timeout: .seconds(10))
		var received = listener.envelopes.makeAsyncIterator()
		#expect(await received.next() == .sample)
	}

	@Test("Sending to a port nobody listens on fails rather than hanging", .timeLimit(.minutes(1)))
	func nobodyListening() async throws {
		await #expect(throws: (any Error).self) {
			try await CompanionClient.send(.sample, to: .hostPort(host: "127.0.0.1", port: 9), timeout: .seconds(3))
		}
	}

	@Test("A companion that never acks makes the send time out", .timeLimit(.minutes(1)))
	func silentCompanion() async throws {
		let silent = try NWListener(using: .tcp)
		silent.newConnectionHandler = { $0.start(queue: companionQueue) }
		do {
			try await silent.open()
		} catch {
			try Test.cancel("Skipped: networking isn't available in this test environment (\(error))")
		}
		defer { silent.cancel() }
		let port = try #require(silent.port)

		await #expect(throws: CompanionTransportError.timedOut) {
			try await CompanionClient.send(.sample, to: .hostPort(host: "127.0.0.1", port: port), timeout: .milliseconds(500))
		}
	}
}
