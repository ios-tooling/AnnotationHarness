import Foundation
import Testing
@testable import AnnotationCore

@MainActor struct CaptureLayoutTests {
	let root = URL.temporaryDirectory.appending(path: "AnnotationHarnessTests-\(UUID().uuidString)", directoryHint: .isDirectory)
	let wide = SessionManifest.Layout.macWindow(size: CGSize(width: 1600, height: 1000))
	let narrow = SessionManifest.Layout.macWindow(size: CGSize(width: 900, height: 700))

	@Test("A capture saved before captures had their own layout still decodes, with none")
	func decodesOldCapture() throws {
		let json = """
		{ "accessibility" : [], "date" : "2026-01-05T09:31:00Z", "id" : "6F9619FF-8B86-D011-B42D-00C04FC964FF", "note" : "Too tight", "number" : 1 }
		"""
		let capture = try JSONDecoder.harness.decode(Capture.self, from: Data(json.utf8))
		#expect(capture.note == "Too tight")
		#expect(capture.layout == nil)
	}

	@Test("A capture's layout survives a save and reload")
	func roundTrip() throws {
		let capture = Capture(number: 1, date: Date(timeIntervalSince1970: 1_790_000_000), note: "", accessibility: [], layout: narrow)
		let data = try JSONEncoder.harness.encode(capture)
		#expect(try JSONDecoder.harness.decode(Capture.self, from: data).layout == narrow)
	}

	@Test("The layout passed to add is kept on the capture, and the harness's call without one leaves it nil")
	func addKeepsLayout() throws {
		let session = HarnessSession.start(in: root, source: .reviews, layout: wide)
		try session.add(original: Data(), annotated: Data(), note: "", screenName: nil, accessibility: [], layout: narrow)
		try session.add(original: Data(), annotated: Data(), note: "", screenName: nil, accessibility: [])
		#expect(session.captures.map(\.layout) == [narrow, nil])
	}

	@Test("Only a capture whose layout differs from the session's gets its own Layout line")
	func reportLine() {
		var manifest = SessionManifest.new(source: .reviews, layout: wide)
		manifest.captures = [
			Capture(number: 1, date: .now, screenName: "Same", note: "", accessibility: [], layout: wide),
			Capture(number: 2, date: .now, screenName: "Smaller", note: "", accessibility: [], layout: narrow),
			Capture(number: 3, date: .now, screenName: "Unknown", note: "", accessibility: []),
		]
		let sections = manifest.captures.map { ReportWriter.section(for: $0, sessionLayout: wide).joined(separator: "\n") }
		#expect(!sections[0].contains("Layout:"))
		#expect(sections[1].contains("\nLayout: Mac window, 900×700 pt\n"))
		#expect(!sections[2].contains("Layout:"))
		#expect(ReportWriter.markdown(for: manifest).components(separatedBy: "\nLayout: ").count == 2)
	}
}
