#if DEBUG
	import Foundation
	import Observation

	/// A run of captures kept in its own folder: `session.json`, `report.md` and `captures/*.png`.
	/// Every change is written straight to disk, so a session survives relaunches until a new one starts.
	@MainActor @Observable final class HarnessSession {
		let folder: URL
		private(set) var manifest: SessionManifest
		@ObservationIgnored var currentScreen: String?

		var captures: [Capture] { manifest.captures }
		var device: DeviceProfile { manifest.device }

		var deviceID: String {
			get { manifest.deviceID }
			set { manifest.deviceID = newValue; try? save() }
		}

		static var sessionsFolder: URL { URL.documentsDirectory.appending(path: "AnnotationHarness", directoryHint: .isDirectory) }

		init(folder: URL, manifest: SessionManifest) {
			self.folder = folder
			self.manifest = manifest
		}

		/// Reopens the newest session in `root`, or starts one if there is none.
		static func resumeOrStart(in root: URL = sessionsFolder) -> HarnessSession {
			let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
			for folder in folders.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
				if let data = try? Data(contentsOf: folder.appending(path: "session.json")), let manifest = try? JSONDecoder.harness.decode(SessionManifest.self, from: data) {
					return HarnessSession(folder: folder, manifest: manifest)
				}
			}
			return start(in: root)
		}

		/// Starts an empty session laid out as `deviceID`.
		static func start(in root: URL = sessionsFolder, deviceID: String = DeviceProfile.standard.id) -> HarnessSession {
			let manifest = SessionManifest.new(deviceID: deviceID)
			let session = HarnessSession(folder: root.appending(path: manifest.id, directoryHint: .isDirectory), manifest: manifest)
			try? session.save()
			return session
		}

		func add(original: Data, annotated: Data, note: String, screenName: String?, accessibility: [AccessibilityNode]) throws {
			let number = (captures.map(\.number).max() ?? 0) + 1
			let capture = Capture(number: number, date: .now, screenName: screenName, note: note, accessibility: accessibility)
			try FileManager.default.createDirectory(at: folder.appending(path: "captures"), withIntermediateDirectories: true)
			try original.write(to: folder.appending(path: capture.originalPath))
			try annotated.write(to: folder.appending(path: capture.annotatedPath))
			manifest.captures.append(capture)
			try save()
		}

		func delete(_ capture: Capture) {
			try? FileManager.default.removeItem(at: folder.appending(path: capture.originalPath))
			try? FileManager.default.removeItem(at: folder.appending(path: capture.annotatedPath))
			manifest.captures.removeAll { $0.id == capture.id }
			try? save()
		}

		/// Writes `session.json` and regenerates `report.md`.
		func save() throws {
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
			try JSONEncoder.harness.encode(manifest).write(to: folder.appending(path: "session.json"))
			try Data(ReportWriter.markdown(for: manifest).utf8).write(to: folder.appending(path: "report.md"))
		}

		var archive: ReportArchive { ReportArchive(folder: folder, name: "\(manifest.appName)-annotations-\(manifest.id)") }
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
#endif
