import Foundation
import Testing
@testable import AnnotationCore

struct CaptureEnvelopeTests {
	@Test("An envelope comes back from its bytes unchanged, PNG included")
	func roundTrip() throws {
		let bytes = try CaptureEnvelope.sample.encoded()
		#expect(try CaptureEnvelope(decoding: bytes) == .sample)
	}

	@Test("The bytes are the magic, the header's length, the header, the PNG's length, then the PNG")
	func framing() throws {
		let bytes = try CaptureEnvelope.sample.encoded()
		#expect(bytes.prefix(4) == Data("AHE1".utf8))
		let headerLength = Int(bytes.bigEndianUInt32(at: 4))
		let header = bytes[8..<(8 + headerLength)]
		let json = try #require(try JSONSerialization.jsonObject(with: header) as? [String: Any])
		#expect(json["png"] == nil)
		#expect(json["screenName"] as? String == "Inbox")
		#expect(bytes.bigEndianUInt32(at: 8 + headerLength) == 256)
		#expect(bytes.suffix(256) == CaptureEnvelope.sample.png)
	}

	@Test("Bytes that don't start with the magic are rejected")
	func badMagic() throws {
		var bytes = try CaptureEnvelope.sample.encoded()
		bytes[0] = UInt8(ascii: "X")
		#expect(throws: CompanionWire.FramingError.badMagic) { try CaptureEnvelope(decoding: bytes) }
	}

	@Test("Bytes cut short anywhere are reported as truncated", arguments: [2, 6, 40, -4, -1])
	func truncated(cut: Int) throws {
		let bytes = try CaptureEnvelope.sample.encoded()
		let length = cut >= 0 ? cut : bytes.count + cut
		#expect(throws: CompanionWire.FramingError.truncated) { try CaptureEnvelope(decoding: bytes.prefix(length)) }
	}
}
