import Foundation
import Testing
@testable import AnnotationCompanion
@testable import AnnotationCore

@MainActor struct InboxTests {
	let root = URL.temporaryDirectory.appending(path: "AnnotationCompanionTests-\(UUID().uuidString)", directoryHint: .isDirectory)

	@Test("An envelope is kept as its header and PNG under its app's folder, and reads back the same")
	func writesAndReads() throws {
		let inbox = Inbox(root: root)
		let item = try inbox.add(.sample(from: .mail))

		#expect(item.folder.deletingLastPathComponent().lastPathComponent == "com.example.mail")
		#expect(try Data(contentsOf: item.imageURL) == CaptureEnvelope.sample(from: .mail).png)
		#expect(FileManager.default.fileExists(atPath: item.folder.appending(path: "envelope.json").path()))
		let read = try #require(inbox.items().first)
		#expect(read.id == item.id)
		#expect(read.envelope == item.envelope)
		#expect(read.envelope.screenName == "Inbox")
		#expect(read.envelope.layout == .macWindow(size: CGSize(width: 1200, height: 800)))
		#expect(read.envelope.accessibility.map(\.label) == ["Reply"])
	}

	@Test("Captures are filed outside Documents/Inbox, which iOS reserves for files other apps hand over and won't let the app write")
	func avoidsReservedInboxFolder() throws {
		let reserved = root.appending(path: "Inbox", directoryHint: .isDirectory)
		try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
		try FileManager.default.createDirectory(at: reserved, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o555])
		let store = CompanionStore(root: root)
		try store.receive(.sample(from: .mail))

		#expect(store.waiting.count == 1)
		#expect(!store.inbox.root.path().hasPrefix(reserved.path()))
	}

	@Test("An app with no bundle ID is filed under its name")
	func keyFallsBackToName() {
		var source = SourceApp.mail
		source.bundleID = ""
		#expect(Inbox.appKey(for: source) == "Mail")
	}

	@Test("Captures are grouped by source app, newest first within each")
	func groupsByApp() throws {
		let store = CompanionStore(root: root)
		try store.receive(.sample(from: .mail, screenName: "Old", minutesLater: 0))
		try store.receive(.sample(from: .notes, screenName: "Notes", minutesLater: 1))
		try store.receive(.sample(from: .mail, screenName: "New", minutesLater: 2))

		#expect(store.apps.map(\.source.name) == ["Mail", "Notes"])
		#expect(store.apps.first?.waiting.map(\.envelope.screenName) == ["New", "Old"])
		#expect(CompanionStore(root: root).apps.map { $0.waiting.count } == [2, 1])
	}

	@Test("Saving a waiting capture puts it in its app's session with its layout and takes it out of the inbox")
	func moveIntoSession() throws {
		let store = CompanionStore(root: root)
		try store.receive(.sample(from: .mail))
		let item = try #require(store.waiting.first)

		let session = store.session(for: item)
		try session.add(original: Data("o".utf8), annotated: Data("a".utf8), note: "Fix it", screenName: item.envelope.screenName, accessibility: item.envelope.accessibility, layout: item.envelope.layout)
		store.remove(item)

		#expect(store.waiting.isEmpty)
		#expect(!FileManager.default.fileExists(atPath: item.folder.path()))
		#expect(session.folder.deletingLastPathComponent().lastPathComponent == "com.example.mail")
		#expect(session.manifest.source == .mail)
		#expect(session.captures.map(\.layout) == [item.envelope.layout])

		let relaunched = CompanionStore(root: root)
		#expect(relaunched.waiting.isEmpty)
		#expect(relaunched.apps.map(\.source.name) == ["Mail"])
		#expect(relaunched.sessions["com.example.mail"]?.captures.map(\.note) == ["Fix it"])
	}

	@Test("A new session replaces the app's current one, which stays on disk")
	func newSession() async throws {
		let store = CompanionStore(root: root)
		try store.receive(.sample(from: .mail))
		let item = try #require(store.waiting.first)
		let first = store.session(for: item)
		try first.add(original: Data(), annotated: Data(), note: "", screenName: nil, accessibility: [])

		try? await Task.sleep(for: .seconds(1.1)) // session IDs are timestamps to the second
		store.startNewSession(for: try #require(store.apps.first))
		let second = try #require(store.sessions["com.example.mail"])
		#expect(second.folder != first.folder)
		#expect(second.captures.isEmpty)
		#expect(FileManager.default.fileExists(atPath: first.folder.path()))
		#expect(CompanionStore(root: root).sessions["com.example.mail"]?.manifest.id == second.manifest.id)
	}
}
