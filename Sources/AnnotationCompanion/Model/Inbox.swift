import AnnotationCore
import Foundation

/// A capture waiting to be annotated, kept in `Inbox/<app>/<uuid>/` as `envelope.json` (the envelope's header) and `original.png`.
package struct InboxItem: Identifiable, Sendable, Equatable {
	package let id: UUID
	package let folder: URL
	/// The envelope's header; its `png` is empty, since the image stays on disk at `imageURL`.
	package let envelope: CaptureEnvelope

	package var imageURL: URL { folder.appending(path: "original.png") }
	package var appKey: String { Inbox.appKey(for: envelope.source) }
}

/// The captures waiting to be annotated, on disk and grouped by source app.
package struct Inbox: Sendable {
	package let root: URL

	package init(root: URL) {
		self.root = root
	}

	/// The folder an app's captures go in: its bundle ID, or its name when that's unknown.
	package static func appKey(for source: SourceApp) -> String {
		let key = source.bundleID.isEmpty ? source.name : source.bundleID
		return key.replacing("/", with: "-").replacing(":", with: "-")
	}

	/// Writes the envelope's header and PNG into a new folder under its app's.
	package func add(_ envelope: CaptureEnvelope) throws -> InboxItem {
		var header = envelope
		header.png = Data()
		let id = UUID()
		let item = InboxItem(id: id, folder: root.appending(path: Self.appKey(for: envelope.source)).appending(path: id.uuidString, directoryHint: .isDirectory), envelope: header)
		try FileManager.default.createDirectory(at: item.folder, withIntermediateDirectories: true)
		try envelope.png.write(to: item.imageURL)
		try Self.encoder.encode(header).write(to: item.folder.appending(path: "envelope.json"))
		return item
	}

	/// Every item that can be read, newest first.
	package func items() -> [InboxItem] {
		let apps = Self.contents(of: root)
		return apps.flatMap(Self.contents(of:)).compactMap(Self.item(in:)).sorted { $0.envelope.date > $1.envelope.date }
	}

	/// Deletes the item's folder, and its app's folder once that's empty.
	package func remove(_ item: InboxItem) {
		try? FileManager.default.removeItem(at: item.folder)
		let appFolder = item.folder.deletingLastPathComponent()
		if Self.contents(of: appFolder).isEmpty { try? FileManager.default.removeItem(at: appFolder) }
	}

	private static func item(in folder: URL) -> InboxItem? {
		guard let data = try? Data(contentsOf: folder.appending(path: "envelope.json")), let envelope = try? decoder.decode(CaptureEnvelope.self, from: data) else { return nil }
		return InboxItem(id: UUID(uuidString: folder.lastPathComponent) ?? UUID(), folder: folder, envelope: envelope)
	}

	private static func contents(of folder: URL) -> [URL] {
		(try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
	}

	private static var encoder: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}

	private static var decoder: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}
}
