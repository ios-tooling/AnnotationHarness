#if DEBUG && os(macOS)
	import AppKit
	import SwiftUI

	@MainActor extension MacSenderTests {
		static func window() -> (NSWindow, NSButton) {
			let window = Self.window(frame: CGRect(x: 100, y: 100, width: 320, height: 200), styleMask: [.titled, .closable])
			let button = NSButton(title: "Reply", target: nil, action: nil)
			button.frame = CGRect(x: 20, y: 20, width: 100, height: 32)
			window.contentView?.addSubview(button)
			return (window, button)
		}

		/// A window on screen, since the accessibility API lists only those, in an app that has finished launching,
		/// since until then it answers no accessibility requests.
		static func window(frame: CGRect, styleMask: NSWindow.StyleMask) -> NSWindow {
			if !hasLaunched {
				NSApplication.shared.finishLaunching()
				hasLaunched = true
			}
			let window = NSWindow(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)
			window.isReleasedWhenClosed = false
			window.orderFront(nil)
			return window
		}

		private static var hasLaunched = false
	}

	/// A small Library screen, like SampleMac's.
	struct SwiftUISample: View {
		@State private var search = ""

		var body: some View {
			VStack(alignment: .leading) {
				TextField("Search books", text: $search)
				Text("The Hobbit")
				Button("Add Book") {}
			}
			.padding()
		}
	}
#endif
