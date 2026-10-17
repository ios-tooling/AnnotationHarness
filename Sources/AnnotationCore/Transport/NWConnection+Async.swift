import Foundation
import Network

/// Why a companion exchange failed, beyond Network.framework's own errors.
package enum CompanionTransportError: Error, Equatable {
	/// The exchange didn't finish in time.
	case timedOut
	/// The other side closed the connection early.
	case closed
	/// The companion answered with something other than the ack byte.
	case badAck
}

/// The queue Network.framework calls back on; it requires one for `start(queue:)`.
let companionQueue = DispatchQueue(label: "AnnotationCore.companion")

extension NWConnection {
	/// Starts the connection and returns once it's ready; throws if it fails or can't reach the other side.
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

	func write(_ data: Data) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
			send(content: data, completion: .contentProcessed { error in
				if let error { continuation.resume(throwing: error) } else { continuation.resume() }
			})
		}
	}

	/// Exactly `count` bytes; throws if the connection closes first.
	func read(exactly count: Int) async throws -> Data {
		guard count > 0 else { return Data() }
		return try await withCheckedThrowingContinuation { continuation in
			receive(minimumIncompleteLength: count, maximumLength: count) { data, _, _, error in
				if let error {
					continuation.resume(throwing: error)
				} else if let data, data.count == count {
					continuation.resume(returning: data)
				} else {
					continuation.resume(throwing: CompanionTransportError.closed)
				}
			}
		}
	}

	/// Reads one envelope's framing piece by piece, so the reader knows where it ends.
	/// Throws `FramingError.tooLarge` for a header over 1 MB or a PNG over 64 MB before reading them.
	func readEnvelope() async throws -> CaptureEnvelope {
		let prefix = try await read(exactly: CompanionWire.magic.count + 4)
		guard prefix.prefix(CompanionWire.magic.count) == CompanionWire.magic else { throw CompanionWire.FramingError.badMagic }
		let headerLength = Int(prefix.bigEndianUInt32(at: CompanionWire.magic.count))
		guard headerLength <= CompanionWire.maxHeaderLength else { throw CompanionWire.FramingError.tooLarge }
		let header = try await read(exactly: headerLength + 4)
		let pngLength = Int(header.bigEndianUInt32(at: header.count - 4))
		guard pngLength <= CompanionWire.maxPNGLength else { throw CompanionWire.FramingError.tooLarge }
		let png = try await read(exactly: pngLength)
		return try CaptureEnvelope(decoding: prefix + header + png)
	}

	/// Runs one exchange on the connection, then closes it; closing it early if it takes longer than `timeout`.
	func exchange<T: Sendable>(timeout: Duration, _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
		try await withThrowingTaskGroup(of: T.self) { group in
			defer { cancel() }
			group.addTask(operation: operation)
			group.addTask {
				try await Task.sleep(for: timeout)
				throw CompanionTransportError.timedOut
			}
			guard let result = try await group.next() else { throw CompanionTransportError.closed }
			group.cancelAll()
			return result
		}
	}
}
