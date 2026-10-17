import Foundation
@testable import AnnotationCore

extension SourceApp {
	static let mail = SourceApp(name: "Mail", bundleID: "com.example.mail", version: "2.0", build: "7", platform: .macOS)
	static let notes = SourceApp(name: "Notes", bundleID: "com.example.notes", version: "1.0", build: "1", platform: .iOS)
}

extension CaptureEnvelope {
	static func sample(from source: SourceApp, screenName: String = "Inbox", minutesLater: Double = 0) -> CaptureEnvelope {
		CaptureEnvelope(source: source, layout: .macWindow(size: CGSize(width: 1200, height: 800)), screenName: screenName, date: Date(timeIntervalSince1970: 1_790_000_000 + minutesLater * 60), accessibility: [AccessibilityNode(traits: ["button"], label: "Reply", frame: CGRect(x: 10, y: 20, width: 80, height: 44))], imageScale: 2, png: Data((0..<256).map { UInt8($0) }))
	}
}
