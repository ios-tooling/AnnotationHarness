import Foundation

/// The record of a session, written next to its captures as `session.json`.
package struct SessionManifest: Codable, Sendable, Equatable {
	package let id: String
	package let started: Date
	package let source: SourceApp
	package var layout: Layout
	package var captures: [Capture] = []

	/// The iPhone the harness imitates; the standard one for layouts that aren't the harness's.
	package var device: DeviceProfile { DeviceProfile.named(layout.deviceID) }

	package static func new(started: Date = .now, source: SourceApp, layout: Layout) -> SessionManifest {
		SessionManifest(id: started.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeSeparator(.omitted)), started: started, source: source, layout: layout)
	}
}

extension SessionManifest {
	/// The keys of `session.json` files written before sources and layouts, which held the app and the harness's device at the top level.
	private enum LegacyKeys: String, CodingKey {
		case appName, appVersion, build, deviceID
	}

	package init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		started = try container.decode(Date.self, forKey: .started)
		captures = try container.decodeIfPresent([Capture].self, forKey: .captures) ?? []
		if container.contains(.source) {
			source = try container.decode(SourceApp.self, forKey: .source)
			layout = try container.decode(Layout.self, forKey: .layout)
		} else {
			let legacy = try decoder.container(keyedBy: LegacyKeys.self)
			source = SourceApp(name: try legacy.decode(String.self, forKey: .appName), bundleID: "", version: try legacy.decode(String.self, forKey: .appVersion), build: try legacy.decode(String.self, forKey: .build), platform: .iOS)
			layout = .harness(deviceID: try legacy.decode(String.self, forKey: .deviceID))
		}
	}
}
