import Foundation
import Network
import Testing
@testable import AnnotationCore

struct EnvelopeLimitTests {
	@Test("A companion refuses a declared header over 1 MB or PNG over 64 MB before reading it", .timeLimit(.minutes(1)), arguments: [true, false])
	func rejectsOversizedLengths(oversizedHeader: Bool) async throws {
		let (errors, continuation) = AsyncStream<any Error>.makeStream()
		let listener = try NWListener(using: .tcp)
		listener.newConnectionHandler = { connection in
			Task {
				do {
					try await connection.open()
					_ = try await connection.readEnvelope()
				} catch {
					continuation.yield(error)
				}
			}
		}
		do {
			try await listener.open()
		} catch {
			try Test.cancel("Skipped: networking isn't available in this test environment (\(error))")
		}
		defer { listener.cancel() }
		let port = try #require(listener.port)

		// Only the lengths are sent, so a reader that tried to read the bodies would wait for the timeout instead.
		var bytes = CompanionWire.magic
		if oversizedHeader {
			bytes.append(Data(bigEndian: UInt32(CompanionWire.maxHeaderLength + 1)))
		} else {
			bytes.append(Data(bigEndian: 2))
			bytes.append(Data("{}".utf8))
			bytes.append(Data(bigEndian: UInt32(CompanionWire.maxPNGLength + 1)))
		}
		let sender = NWConnection(to: .hostPort(host: "127.0.0.1", port: port), using: .tcp)
		defer { sender.cancel() }
		try await sender.open()
		try await sender.write(bytes)

		var received = errors.makeAsyncIterator()
		let error = await received.next()
		#expect(error as? CompanionWire.FramingError == .tooLarge)
	}
}
