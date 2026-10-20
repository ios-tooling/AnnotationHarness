import AnnotationCore
import Foundation
import Observation

/// A source app in the sidebar, with the captures it has waiting, newest first.
package struct CompanionApp: Identifiable, Equatable {
	package let key: String
	package let source: SourceApp
	package let waiting: [InboxItem]

	package var id: String { key }
}

/// The companion's state: the inbox of captures waiting to be annotated, and one session per source app
/// (`Sessions/<app>/<session>/`), the newest of which is resumed on launch.
@MainActor @Observable package final class CompanionStore {
	package let inbox: Inbox
	package let sessionsRoot: URL
	package private(set) var waiting: [InboxItem]
	package private(set) var sessions: [String: HarnessSession]
	/// The name the companion is advertised under, which senders list as the target.
	package internal(set) var advertisedName: String?
	/// Why listening or filing the last capture failed, if it did.
	package internal(set) var problem: String?
	/// The capture that arrived most recently while the companion ran, so the interface can show its app.
	package private(set) var latestArrival: InboxItem?

	@ObservationIgnored let listener = CompanionListener()
	@ObservationIgnored var listening: Task<Void, Never>?
	@ObservationIgnored var receiving: [Task<Void, Never>] = []

	package init(root: URL = .documentsDirectory) {
		// Not `Inbox`: iOS keeps `Documents/Inbox` for files other apps hand over, and on a device the app can't write there.
		inbox = Inbox(root: root.appending(path: "Waiting", directoryHint: .isDirectory))
		sessionsRoot = root.appending(path: "Sessions", directoryHint: .isDirectory)
		waiting = inbox.items()
		sessions = Self.newestSessions(in: sessionsRoot)
	}

	/// Every app with captures waiting or a session, by name.
	package var apps: [CompanionApp] {
		var sources = sessions.mapValues(\.manifest.source)
		for item in waiting.reversed() { sources[item.appKey] = item.envelope.source }
		return sources.map { key, source in CompanionApp(key: key, source: source, waiting: waiting.filter { $0.appKey == key }) }
			.sorted { $0.source.name.localizedStandardCompare($1.source.name) == .orderedAscending }
	}

	/// Files an incoming capture in the inbox.
	package func receive(_ envelope: CaptureEnvelope) throws {
		let item = try inbox.add(envelope)
		waiting.append(item)
		waiting.sort { $0.envelope.date > $1.envelope.date }
		latestArrival = item
	}

	/// Takes a capture out of the inbox: deleted, or saved into its app's session.
	package func remove(_ item: InboxItem) {
		inbox.remove(item)
		waiting.removeAll { $0.id == item.id }
	}

	/// The session `item` is saved into: its app's, started from the item's source and layout when the app has none yet.
	package func session(for item: InboxItem) -> HarnessSession {
		if let session = sessions[item.appKey] { return session }
		let session = HarnessSession.start(in: sessionsRoot.appending(path: item.appKey, directoryHint: .isDirectory), source: item.envelope.source, layout: item.envelope.layout)
		sessions[item.appKey] = session
		return session
	}

	/// Starts a fresh session for the app, laid out like its newest waiting capture, or else like its current session.
	/// The old session stays on disk.
	package func startNewSession(for app: CompanionApp) {
		guard let layout = app.waiting.first?.envelope.layout ?? sessions[app.key]?.manifest.layout else { return }
		sessions[app.key] = HarnessSession.start(in: sessionsRoot.appending(path: app.key, directoryHint: .isDirectory), source: app.source, layout: layout)
	}

	private static func newestSessions(in root: URL) -> [String: HarnessSession] {
		let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
		var sessions: [String: HarnessSession] = [:]
		for folder in folders {
			sessions[folder.lastPathComponent] = HarnessSession.newest(in: folder)
		}
		return sessions
	}
}
