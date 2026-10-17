import Foundation
import Observation

/// A run of captures kept in its own folder: `session.json`, `report.md` and `captures/*.png`.
/// Every change is written straight to disk, so a session survives relaunches until a new one starts.
@MainActor @Observable package final class HarnessSession {
	package let folder: URL
	package private(set) var manifest: SessionManifest
	@ObservationIgnored var currentScreen: String?

	package var captures: [Capture] { manifest.captures }
	package var device: DeviceProfile { manifest.device }

	/// The harness's device; setting it switches the session to the harness layout.
	package var deviceID: String {
		get { manifest.layout.deviceID ?? DeviceProfile.standard.id }
		set { manifest.layout = .harness(deviceID: newValue); try? save() }
	}

	package static var sessionsFolder: URL { URL.documentsDirectory.appending(path: "AnnotationHarness", directoryHint: .isDirectory) }

	package init(folder: URL, manifest: SessionManifest) {
		self.folder = folder
		self.manifest = manifest
	}

	/// Reopens the newest session in `root`, or starts one if there is none.
	package static func resumeOrStart(in root: URL = sessionsFolder) -> HarnessSession {
		newest(in: root) ?? start(in: root)
	}

	/// The newest session in `root` that can be read, if any.
	package static func newest(in root: URL) -> HarnessSession? {
		let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
		for folder in folders.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
			if let data = try? Data(contentsOf: folder.appending(path: "session.json")), let manifest = try? JSONDecoder.harness.decode(SessionManifest.self, from: data) {
				return HarnessSession(folder: folder, manifest: manifest)
			}
		}
		return nil
	}

	/// Starts an empty session for this app, laid out as `deviceID` in the harness.
	package static func start(in root: URL = sessionsFolder, deviceID: String = DeviceProfile.standard.id) -> HarnessSession {
		start(in: root, source: SourceApp(bundle: .main), layout: .harness(deviceID: deviceID))
	}

	/// Starts an empty session for captures from `source`, laid out as `layout`.
	package static func start(in root: URL, source: SourceApp, layout: SessionManifest.Layout) -> HarnessSession {
		let manifest = SessionManifest.new(source: source, layout: layout)
		let session = HarnessSession(folder: root.appending(path: manifest.id, directoryHint: .isDirectory), manifest: manifest)
		try? session.save()
		return session
	}

	/// Saves a capture's images and adds it; `layout` records what it shows when that can differ from the session's,
	/// and `date` is when the screenshot was taken.
	package func add(original: Data, annotated: Data, note: String, screenName: String?, accessibility: [AccessibilityNode], layout: SessionManifest.Layout? = nil, date: Date = .now) throws {
		let number = (captures.map(\.number).max() ?? 0) + 1
		let capture = Capture(number: number, date: date, screenName: screenName, note: note, accessibility: accessibility, layout: layout)
		try FileManager.default.createDirectory(at: folder.appending(path: "captures"), withIntermediateDirectories: true)
		try original.write(to: folder.appending(path: capture.originalPath))
		try annotated.write(to: folder.appending(path: capture.annotatedPath))
		manifest.captures.append(capture)
		try save()
	}

	package func delete(_ capture: Capture) {
		try? FileManager.default.removeItem(at: folder.appending(path: capture.originalPath))
		try? FileManager.default.removeItem(at: folder.appending(path: capture.annotatedPath))
		manifest.captures.removeAll { $0.id == capture.id }
		try? save()
	}

	/// Writes `session.json` and regenerates `report.md`.
	package func save() throws {
		try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
		try JSONEncoder.harness.encode(manifest).write(to: folder.appending(path: "session.json"))
		try Data(ReportWriter.markdown(for: manifest).utf8).write(to: folder.appending(path: "report.md"))
	}

	package var archive: ReportArchive { ReportArchive(folder: folder, name: "\(manifest.source.name)-annotations-\(manifest.id)") }
}

extension JSONEncoder {
	static var harness: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}
}

extension JSONDecoder {
	static var harness: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}
}
