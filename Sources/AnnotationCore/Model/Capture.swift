import Foundation

/// One annotated screenshot in a session.
package struct Capture: Codable, Identifiable, Sendable, Equatable {
	package var id = UUID()
	package let number: Int
	package let date: Date
	package var screenName: String?
	package var note: String
	package let accessibility: [AccessibilityNode]
	/// What this capture shows, when it can differ from the session's (a Mac app's windows come in many sizes); `nil` in older sessions and the harness's.
	package var layout: SessionManifest.Layout?

	package var title: String { screenName ?? "Capture \(number)" }
	package var originalPath: String { "captures/\(fileStem)-original.png" }
	package var annotatedPath: String { "captures/\(fileStem)-annotated.png" }

	private var fileStem: String { String(format: "%03d", number) }
}
