import Foundation
import Testing
@testable import AnnotationCore

struct ReportLayoutTests {
	func report(_ layout: SessionManifest.Layout, source: SourceApp = .reviews) -> String {
		ReportWriter.markdown(for: .new(source: source, layout: layout))
	}

	@Test("A harness session keeps today's layout line and frame origin")
	func harness() {
		let report = report(.harness(deviceID: "iphone-16e"))
		#expect(report.contains("- Layout: iPhone 16e, 390×844 pt, run in AnnotationHarness on an iPad (its own iPhone-sized window with compact size classes; the status bar is drawn by the harness and the keyboard is the iPad's)"))
		#expect(report.contains("Frames are in points from the top-left of the iPhone screen."))
	}

	@Test("A Mac window's frames are measured from the window's top-left")
	func macWindow() {
		let report = report(.macWindow(size: CGSize(width: 1200, height: 800)))
		#expect(report.contains("- Layout: Mac window, 1200×800 pt\n"))
		#expect(report.contains("Frames are in points from the top-left of the window."))
	}

	@Test("A whole screen names the device model and measures from the screen's top-left")
	func screen() {
		let report = report(.screen(model: "iPhone 17 Pro", size: CGSize(width: 402, height: 874)))
		#expect(report.contains("- Layout: iPhone 17 Pro, 402×874 pt\n"))
		#expect(report.contains("Frames are in points from the top-left of the screen."))
	}

	@Test("The App line adds the bundle ID when it's known, and the platform")
	func appLine() {
		#expect(report(.harness(deviceID: "iphone-se")).contains("- App: Reviews 1.2 (34), com.example.reviews, iOS\n"))
		var unknown = SourceApp.reviews
		unknown.bundleID = ""
		unknown.platform = .macOS
		#expect(report(.harness(deviceID: "iphone-se"), source: unknown).contains("- App: Reviews 1.2 (34), macOS\n"))
	}
}
