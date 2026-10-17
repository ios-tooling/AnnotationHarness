import Foundation

/// The names senders and the companion agree on, and the framing errors.
package enum CompanionWire {
	/// The Bonjour service the companion advertises.
	package static let serviceType = "_annotharness._tcp"
	/// The URL scheme the companion registers for same-device sends.
	package static let urlScheme = "annotationharness"
	/// Opened after a same-device send, so the companion reads the envelope off the pasteboard.
	package static let receiveURL = URL(string: "\(urlScheme)://receive")!
	/// The pasteboard type that holds an encoded envelope.
	package static let pasteboardType = "com.annotationharness.envelope"

	/// The first four bytes of an encoded envelope.
	static let magic = Data("AHE1".utf8)
	/// The byte the companion sends back once an envelope has decoded.
	static let ack: UInt8 = 0x06
	/// The longest JSON header a companion reads off the network.
	static let maxHeaderLength = 1 << 20
	/// The largest PNG a companion reads off the network.
	static let maxPNGLength = 64 << 20

	/// Why bytes couldn't be read as an envelope.
	package enum FramingError: Error, Equatable {
		/// The bytes don't start with `AHE1`.
		case badMagic
		/// The bytes end before the lengths they declare.
		case truncated
		/// A declared length is over the limit a companion reads off the network.
		case tooLarge
	}
}

extension Data {
	/// `value` as four big-endian bytes.
	init(bigEndian value: UInt32) {
		self = Data([UInt8(value >> 24 & 0xFF), UInt8(value >> 16 & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)])
	}

	/// The big-endian `UInt32` in the four bytes starting `offset` bytes in.
	func bigEndianUInt32(at offset: Int) -> UInt32 {
		dropFirst(offset).prefix(4).reduce(0) { $0 << 8 | UInt32($1) }
	}
}
