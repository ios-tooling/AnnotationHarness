import Foundation
import Testing
@testable import AnnotationCore

struct SessionManifestTests {
	/// A `session.json` as written before sources and layouts, with the app and device at the top level.
	let oldJSON = """
	{
	  "appName" : "Reviews",
	  "appVersion" : "1.2",
	  "build" : "34",
	  "captures" : [
	    {
	      "accessibility" : [ { "depth" : 0, "frame" : [ [ 16, 70 ], [ 120, 34 ] ], "label" : "Reviews", "traits" : [ "header" ] } ],
	      "date" : "2026-01-05T09:31:00Z",
	      "id" : "6F9619FF-8B86-D011-B42D-00C04FC964FF",
	      "note" : "Too tight",
	      "number" : 1,
	      "screenName" : "Reviews"
	    }
	  ],
	  "deviceID" : "iphone-se",
	  "id" : "20260105T093000Z",
	  "started" : "2026-01-05T09:30:00Z"
	}
	"""

	@Test("An old session.json still opens, as a harness session from an iOS app whose bundle ID wasn't recorded")
	func decodesOldManifest() throws {
		let manifest = try JSONDecoder.harness.decode(SessionManifest.self, from: Data(oldJSON.utf8))
		#expect(manifest.id == "20260105T093000Z")
		#expect(manifest.source == SourceApp(name: "Reviews", bundleID: "", version: "1.2", build: "34", platform: .iOS))
		#expect(manifest.layout == .harness(deviceID: "iphone-se"))
		#expect(manifest.device.id == "iphone-se")
		#expect(manifest.captures.map(\.note) == ["Too tight"])
		#expect(manifest.captures.first?.date == ISO8601DateFormatter().date(from: "2026-01-05T09:31:00Z"))
		#expect(manifest.captures.first?.accessibility.first?.frame == CGRect(x: 16, y: 70, width: 120, height: 34))
	}

	@Test("A new manifest survives a save and reload with its source and layout")
	func roundTrip() throws {
		let manifest = SessionManifest.new(started: Date(timeIntervalSince1970: 1_790_000_000), source: .reviews, layout: .screen(model: "iPad Pro", size: CGSize(width: 1032, height: 1376)))
		let data = try JSONEncoder.harness.encode(manifest)
		#expect(try JSONDecoder.harness.decode(SessionManifest.self, from: data) == manifest)
	}

	@Test("Setting the harness's device switches the session to that harness layout")
	@MainActor func deviceIDFollowsLayout() {
		let root = URL.temporaryDirectory.appending(path: "AnnotationHarnessTests-\(UUID().uuidString)", directoryHint: .isDirectory)
		let session = HarnessSession.start(in: root, source: .reviews, layout: .macWindow(size: CGSize(width: 800, height: 600)))
		#expect(session.deviceID == DeviceProfile.standard.id)
		session.deviceID = "iphone-air"
		#expect(session.manifest.layout == .harness(deviceID: "iphone-air"))
		#expect(session.archive.name == "Reviews-annotations-\(session.manifest.id)")
	}
}
