import Foundation
import Testing
@testable import AnnotationCompanion
@testable import AnnotationCore

@MainActor struct AppRemovalTests {
	let root = URL.temporaryDirectory.appending(path: "AnnotationCompanionTests-\(UUID().uuidString)", directoryHint: .isDirectory)

	@Test("Removing an app deletes its waiting captures and every session from disk, and leaves other apps alone")
	func removesEverythingForTheApp() async throws {
		let store = CompanionStore(root: root)
		try store.receive(.sample(from: .mail, screenName: "Saved"))
		try store.receive(.sample(from: .notes, screenName: "Notes"))
		let saved = try #require(store.waiting.first { $0.appKey == "com.example.mail" })
		let first = store.session(for: saved)
		try first.add(original: Data("o".utf8), annotated: Data("a".utf8), note: "", screenName: nil, accessibility: [])
		store.remove(saved)
		try? await Task.sleep(for: .seconds(1.1)) // session IDs are timestamps to the second
		let mail = try #require(store.apps.first { $0.key == "com.example.mail" })
		store.startNewSession(for: mail)
		let second = try #require(store.sessions["com.example.mail"])
		try store.receive(.sample(from: .mail, screenName: "Waiting"))
		let waiting = try #require(store.waiting.first { $0.appKey == "com.example.mail" })
		let app = try #require(store.apps.first { $0.key == "com.example.mail" })
		#expect(store.savedCaptureCount(for: app) == 1)

		store.removeApp(app)

		#expect(store.apps.map(\.key) == ["com.example.notes"])
		#expect(store.sessions["com.example.mail"] == nil)
		#expect(store.latestArrival == nil)
		for folder in [waiting.folder, first.folder, second.folder] {
			#expect(!FileManager.default.fileExists(atPath: folder.path()))
		}
		#expect(!FileManager.default.fileExists(atPath: store.sessionsRoot.appending(path: "com.example.mail").path()))
		#expect(!FileManager.default.fileExists(atPath: store.inbox.root.appending(path: "com.example.mail").path()))
		let notes = try #require(store.waiting.first)
		#expect(FileManager.default.fileExists(atPath: notes.imageURL.path()))
		#expect(CompanionStore(root: root).apps.map(\.key) == ["com.example.notes"])
	}

	@Test("A capture from a removed app brings it back with only that capture")
	func arrivalRecreatesApp() throws {
		let store = CompanionStore(root: root)
		try store.receive(.sample(from: .mail, screenName: "Old"))
		store.removeApp(try #require(store.apps.first))
		try store.receive(.sample(from: .mail, screenName: "New"))

		#expect(store.apps.map(\.key) == ["com.example.mail"])
		#expect(store.apps.first?.waiting.map(\.envelope.screenName) == ["New"])
		#expect(store.latestArrival?.appKey == "com.example.mail")
	}
}
