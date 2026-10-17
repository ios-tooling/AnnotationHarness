import Foundation
@testable import AnnotationCore

extension SourceApp {
	static let reviews = SourceApp(name: "Reviews", bundleID: "com.example.reviews", version: "1.2", build: "34", platform: .iOS)
}

extension CaptureEnvelope {
	static let sample = CaptureEnvelope(source: .reviews, layout: .macWindow(size: CGSize(width: 1200, height: 800)), screenName: "Inbox", date: Date(timeIntervalSince1970: 1_790_000_000), accessibility: [AccessibilityNode(traits: ["button"], label: "Reply", frame: CGRect(x: 10, y: 20, width: 80, height: 44))], imageScale: 2, png: Data((0..<256).map { UInt8($0) }))
}
