#if DEBUG && os(macOS)
	import AnnotationCore
	import AppKit

	/// Captures a Mac app's window for the companion.
	///
	/// AppKit on purpose: `cacheDisplay` on the window's frame view draws the title bar and toolbar too, and,
	/// unlike ScreenCaptureKit, needs no Screen Recording permission. It can miss Metal, video and some layer content.
	@MainActor enum WindowCapture {
		/// A Mac app sends over the network only.
		static let sameDeviceAvailable = false

		/// The key window, or else the main window.
		static func envelope(screenName: String?) -> CaptureEnvelope? {
			guard let window = NSApp.keyWindow ?? NSApp.mainWindow else { return nil }
			return envelope(of: window, screenName: screenName)
		}

		/// The window as a PNG at its backing scale, with its accessibility elements in points from its top-left.
		static func envelope(of window: NSWindow, screenName: String?, date: Date = .now) -> CaptureEnvelope? {
			guard let view = window.contentView?.superview ?? window.contentView, let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
			view.cacheDisplay(in: view.bounds, to: bitmap)
			guard let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
			let scale = view.bounds.width > 0 ? CGFloat(bitmap.pixelsWide) / view.bounds.width : window.backingScaleFactor
			let nodes = MacAccessibilityReader.nodes(in: window)
			return CaptureEnvelope(source: SourceApp(bundle: .main), layout: .macWindow(size: window.frame.size), screenName: screenName, date: date, accessibility: nodes, imageScale: scale, png: png)
		}
	}
#endif
