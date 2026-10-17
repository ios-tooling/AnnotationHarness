import Foundation

/// One screenshot on its way from a source app to the companion, with what's needed to file and report it.
///
/// Its `Codable` form is the JSON header and leaves out the PNG, which travels after the header in `encoded()`.
package struct CaptureEnvelope: Codable, Sendable, Equatable {
	package var source: SourceApp
	package var layout: SessionManifest.Layout
	package var screenName: String?
	package var date: Date
	package var accessibility: [AccessibilityNode]
	/// Pixels per point in the PNG.
	package var imageScale: CGFloat
	package var png = Data()

	private enum CodingKeys: String, CodingKey {
		case source, layout, screenName, date, accessibility, imageScale
	}

	package init(source: SourceApp, layout: SessionManifest.Layout, screenName: String?, date: Date = .now, accessibility: [AccessibilityNode], imageScale: CGFloat, png: Data) {
		self.source = source
		self.layout = layout
		self.screenName = screenName
		self.date = date
		self.accessibility = accessibility
		self.imageScale = imageScale
		self.png = png
	}

	/// The bytes sent over the network or put on the pasteboard:
	/// `AHE1`, the header's length (UInt32, big-endian), the JSON header, the PNG's length (UInt32, big-endian), the PNG.
	package func encoded() throws -> Data {
		let header = try JSONEncoder.envelope.encode(self)
		var data = CompanionWire.magic
		data.append(Data(bigEndian: UInt32(header.count)))
		data.append(header)
		data.append(Data(bigEndian: UInt32(png.count)))
		data.append(png)
		return data
	}

	/// Reads bytes laid out by `encoded()`; throws `CompanionWire.FramingError` when they aren't, or the header's decoding error.
	package init(decoding data: Data) throws {
		let data = Data(data)
		let magic = CompanionWire.magic
		guard data.count >= magic.count else { throw CompanionWire.FramingError.truncated }
		guard data.prefix(magic.count) == magic else { throw CompanionWire.FramingError.badMagic }
		guard data.count >= magic.count + 4 else { throw CompanionWire.FramingError.truncated }
		let headerStart = magic.count + 4
		let headerEnd = headerStart + Int(data.bigEndianUInt32(at: magic.count))
		guard data.count >= headerEnd + 4 else { throw CompanionWire.FramingError.truncated }
		let pngStart = headerEnd + 4
		let pngEnd = pngStart + Int(data.bigEndianUInt32(at: headerEnd))
		guard data.count >= pngEnd else { throw CompanionWire.FramingError.truncated }
		self = try JSONDecoder.harness.decode(CaptureEnvelope.self, from: data[headerStart..<headerEnd])
		png = Data(data[pngStart..<pngEnd])
	}
}

extension JSONEncoder {
	/// Compact, with ISO 8601 dates as in `session.json`.
	static var envelope: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}
}
