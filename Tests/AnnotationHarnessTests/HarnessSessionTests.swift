import Foundation
import Testing
@testable import AnnotationHarness

@MainActor struct HarnessSessionTests {
	let root = URL.temporaryDirectory.appending(path: "AnnotationHarnessTests-\(UUID().uuidString)", directoryHint: .isDirectory)

	@Test("A relaunch reopens the newest session with its captures, so notes aren't lost between runs")
	func resumesNewestSession() throws {
		let session = HarnessSession.start(in: root, deviceID: "iphone-se")
		try session.add(original: Data("a".utf8), annotated: Data("b".utf8), note: "Too tight", screenName: "Reviews", accessibility: [])

		let resumed = HarnessSession.resumeOrStart(in: root)
		#expect(resumed.manifest.id == session.manifest.id)
		#expect(resumed.captures.map(\.note) == ["Too tight"])
		#expect(resumed.device.id == "iphone-se")
	}

	@Test("Each capture's images land where the report links them")
	func writesImagesAtReportPaths() throws {
		let session = HarnessSession.start(in: root)
		try session.add(original: Data("a".utf8), annotated: Data("b".utf8), note: "", screenName: nil, accessibility: [])
		try session.add(original: Data("c".utf8), annotated: Data("d".utf8), note: "", screenName: nil, accessibility: [])

		let second = try #require(session.captures.last)
		#expect(second.number == 2)
		#expect(try Data(contentsOf: session.folder.appending(path: second.annotatedPath)) == Data("d".utf8))
		let report = try String(contentsOf: session.folder.appending(path: "report.md"), encoding: .utf8)
		#expect(report.contains("](\(second.annotatedPath))"))
	}

	@Test("Deleting a capture removes its files and keeps later numbers stable")
	func deleteKeepsNumbers() throws {
		let session = HarnessSession.start(in: root)
		try session.add(original: Data(), annotated: Data(), note: "one", screenName: nil, accessibility: [])
		try session.add(original: Data(), annotated: Data(), note: "two", screenName: nil, accessibility: [])
		let first = try #require(session.captures.first)

		session.delete(first)
		#expect(!FileManager.default.fileExists(atPath: session.folder.appending(path: first.originalPath).path()))
		try session.add(original: Data(), annotated: Data(), note: "three", screenName: nil, accessibility: [])
		#expect(session.captures.map(\.number) == [2, 3])
	}

	@Test("The shared archive is a zip of the session folder, the single file handed to an agent")
	func archiveIsZip() throws {
		let session = HarnessSession.start(in: root)
		try session.add(original: Data("a".utf8), annotated: Data("b".utf8), note: "", screenName: nil, accessibility: [])

		let zip = try session.archive.makeZip()
		let header = try Data(contentsOf: zip).prefix(2)
		#expect(header == Data("PK".utf8))
	}
}
