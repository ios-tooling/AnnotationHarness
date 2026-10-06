import Foundation
import Testing
@testable import AnnotationHarness

struct ReportWriterTests {
	let capture = Capture(number: 1, date: .now, screenName: "Reviews", note: "Rating stars overlap the title", accessibility: [
		AccessibilityNode(depth: 0, traits: ["header"], label: "Reviews", frame: CGRect(x: 16, y: 70, width: 120, height: 34)),
		AccessibilityNode(depth: 1, traits: ["button"], label: "Reply", identifier: "reply", frame: CGRect(x: 300, y: 200, width: 80, height: 44)),
	])

	@Test("A capture's section carries what an agent needs to find and fix it: title, image, note and elements")
	func sectionContents() {
		let section = ReportWriter.section(for: capture).joined(separator: "\n")
		#expect(section.contains("## 1. Reviews"))
		#expect(section.contains("![Reviews, annotated](captures/001-annotated.png)"))
		#expect(section.contains("Rating stars overlap the title"))
		#expect(section.contains("  - button \"Reply\" #reply (300, 200, 80×44)"))
	}

	@Test("An empty note says so rather than leaving a blank the agent might misread")
	func emptyNote() {
		var silent = capture
		silent.note = "  "
		#expect(ReportWriter.section(for: silent).contains("_No note._"))
	}

	@Test("The header names the layout, so an agent knows it was an iPhone screen shown on an iPad")
	func headerNamesLayout() {
		var manifest = SessionManifest.new(deviceID: "iphone-16e")
		manifest.captures = [capture]
		let report = ReportWriter.markdown(for: manifest)
		#expect(report.contains("iPhone 16e, 390×844 pt"))
		#expect(report.contains("- Captures: 1"))
	}

	@Test("Only the launch argument turns the harness on")
	func launchArgument() {
		#expect(AnnotationHarness.isRequested(arguments: ["App", "-AnnotationHarness"]))
		#expect(!AnnotationHarness.isRequested(arguments: ["App"]))
	}

	@Test("The screen shows at real size when it fits and shrinks only when it must")
	func fitScale() {
		let device = DeviceProfile.named("iphone-17-pro")
		#expect(device.fitScale(in: CGSize(width: 800, height: 1100)) == 1)
		#expect(device.fitScale(in: CGSize(width: 800, height: 437)) == 0.5)
	}
}
