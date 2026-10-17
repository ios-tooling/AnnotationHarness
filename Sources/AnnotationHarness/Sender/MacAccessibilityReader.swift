#if DEBUG && os(macOS)
	import AnnotationCore
	import AppKit
	import ApplicationServices

	/// Walks the window's accessibility tree, the one VoiceOver sees, and keeps the readable elements on the window,
	/// in reading order.
	///
	/// It reads through the accessibility client API, as VoiceOver does, on the app's own process. Calling the
	/// `NSAccessibility` methods directly finds no SwiftUI elements: a hosting view builds them only once an
	/// accessibility client asks, and they implement those methods without declaring the protocol. Asking the
	/// app's own process is public API and needs no accessibility permission.
	@MainActor enum MacAccessibilityReader {
		static func nodes(in window: NSWindow) -> [AccessibilityNode] {
			guard let element = element(for: window), let frame = MacAccessibilityAttributes(element).frame else { return [] }
			var walk = Walk(windowFrame: frame)
			for child in element.elements(kAXChildrenAttribute) { walk.visit(child, depth: 0) }
			return walk.nodes
		}

		/// The window's element, by its frame: the frontmost of the app's windows where it is. The client API's screen
		/// coordinates start at the main display's top-left, AppKit's at its bottom-left.
		static func element(for window: NSWindow) -> AXUIElement? {
			guard let mainDisplay = NSScreen.screens.first else { return nil }
			let frame = window.frame
			let expected = CGRect(x: frame.minX, y: mainDisplay.frame.maxY - frame.maxY, width: frame.width, height: frame.height)
			return AXUIElementCreateApplication(getpid()).elements(kAXWindowsAttribute).first { candidate in
				guard let found = MacAccessibilityAttributes(candidate).frame else { return false }
				return abs(found.minX - expected.minX) <= 1 && abs(found.minY - expected.minY) <= 1 && abs(found.width - expected.width) <= 1 && abs(found.height - expected.height) <= 1
			}
		}

		@MainActor private struct Walk {
			let windowFrame: CGRect
			var nodes: [AccessibilityNode] = []

			/// An element with something to read is listed, and what's inside it is listed one level deeper;
			/// one with nothing to read (a plain container) is skipped, and its contents stay at its level.
			/// The window's own buttons (close, minimize, zoom) belong to the window, not the app, so they're left out.
			mutating func visit(_ element: AXUIElement, depth: Int) {
				let attributes = MacAccessibilityAttributes(element)
				if let subrole = attributes.subrole, Self.windowButtons.contains(subrole) { return }
				var childDepth = depth
				if let node = node(for: attributes, depth: depth) {
					nodes.append(node)
					childDepth += 1
				}
				for child in element.elements(kAXChildrenAttribute) { visit(child, depth: childDepth) }
			}

			/// A text field with no label is read by its placeholder, as on iOS.
			func node(for element: MacAccessibilityAttributes, depth: Int) -> AccessibilityNode? {
				let label = element.description ?? element.title ?? element.placeholder
				guard label != nil || element.value != nil || element.help != nil, let screen = element.frame else { return nil }
				// Both are in the client API's screen coordinates, so this is points from the window's top-left.
				let frame = screen.offsetBy(dx: -windowFrame.minX, dy: -windowFrame.minY)
				guard frame.intersects(CGRect(origin: .zero, size: windowFrame.size)) else { return nil }
				return AccessibilityNode(depth: depth, traits: Self.traits(of: element), label: label, value: element.value, hint: element.help, identifier: element.identifier, frame: frame)
			}

			/// The role in the iOS reader's words where there's a match (`button`, `text`), otherwise AppKit's without the `AX`.
			static func traits(of element: MacAccessibilityAttributes) -> [String] {
				var traits: [String] = []
				if let role = element.role { traits.append(roleNames[role] ?? String(role.rawValue.trimmingPrefix("AX"))) }
				if element.subrole == .searchField { traits.append("searchField") }
				if element.isSelected { traits.append("selected") }
				if !element.isEnabled { traits.append("disabled") }
				return traits
			}

			static let windowButtons: Set<NSAccessibility.Subrole> = [.closeButton, .minimizeButton, .zoomButton, .fullScreenButton, .toolbarButton]

			static let roleNames: [NSAccessibility.Role: String] = [
				.button: "button", .link: "link", .image: "image", .staticText: "text", .checkBox: "toggle",
				.slider: "adjustable", .incrementor: "adjustable", .group: "group", .textField: "textField",
			]
		}
	}
#endif
