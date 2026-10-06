#if DEBUG
	import Foundation

	/// One annotated screenshot in a session.
	struct Capture: Codable, Identifiable, Sendable, Equatable {
		var id = UUID()
		let number: Int
		let date: Date
		var screenName: String?
		var note: String
		let accessibility: [AccessibilityNode]

		var title: String { screenName ?? "Capture \(number)" }
		var originalPath: String { "captures/\(fileStem)-original.png" }
		var annotatedPath: String { "captures/\(fileStem)-annotated.png" }

		private var fileStem: String { String(format: "%03d", number) }
	}

	/// The record of a session, written next to its captures as `session.json`.
	struct SessionManifest: Codable, Sendable, Equatable {
		let id: String
		let started: Date
		let appName: String
		let appVersion: String
		let build: String
		var deviceID: String
		var captures: [Capture] = []

		var device: DeviceProfile { DeviceProfile.named(deviceID) }

		static func new(started: Date = .now, deviceID: String = DeviceProfile.standard.id, bundle: Bundle = .main) -> SessionManifest {
			let info = bundle.infoDictionary ?? [:]
			let name = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? "App"
			return SessionManifest(id: started.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeSeparator(.omitted)), started: started, appName: name, appVersion: info["CFBundleShortVersionString"] as? String ?? "?", build: info["CFBundleVersion"] as? String ?? "?", deviceID: deviceID)
		}
	}
#endif
