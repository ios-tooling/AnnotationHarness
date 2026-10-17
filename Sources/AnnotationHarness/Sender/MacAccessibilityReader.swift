#if DEBUG && os(macOS)
	import AnnotationCore
	import AppKit

	/// Walks the window's accessibility tree, the one VoiceOver sees, and keeps the readable elements on the window,
	/// in reading order. It's the app's own process, so no private API is needed.
	@MainActor enum MacAccessibilityReader {
		static func nodes(in window: NSWindow) -> [AccessibilityNode] {
			var walk = Walk(windowFrame: window.frame)
			for child in children(of: window) { walk.visit(child, depth: 0) }
			return walk.nodes
		}

		static func children(of element: any NSAccessibilityProtocol) -> [any NSAccessibilityProtocol] {
			(element.accessibilityChildren() ?? []).compactMap { $0 as? any NSAccessibilityProtocol }
		}

		@MainActor private struct Walk {
			let windowFrame: CGRect
			var nodes: [AccessibilityNode] = []

			/// An element with something to read is listed, and what's inside it is listed one level deeper;
			/// one with nothing to read (a plain container) is skipped, and its contents stay at its level.
			mutating func visit(_ element: any NSAccessibilityProtocol, depth: Int) {
				if element.isAccessibilityHidden() { return }
				var childDepth = depth
				if let node = node(for: element, depth: depth) {
					nodes.append(node)
					childDepth += 1
				}
				for child in MacAccessibilityReader.children(of: element) { visit(child, depth: childDepth) }
			}

			func node(for element: any NSAccessibilityProtocol, depth: Int) -> AccessibilityNode? {
				let label = Self.text(element.accessibilityLabel()) ?? Self.text(element.accessibilityTitle())
				let value = Self.text(element.accessibilityValue())
				let hint = Self.text(element.accessibilityHelp())
				guard label != nil || value != nil || hint != nil else { return nil }
				// Screen coordinates, origin bottom-left, into points from the window's top-left.
				let screen = element.accessibilityFrame()
				let frame = CGRect(x: screen.minX - windowFrame.minX, y: windowFrame.maxY - screen.maxY, width: screen.width, height: screen.height)
				guard frame.intersects(CGRect(origin: .zero, size: windowFrame.size)) else { return nil }
				return AccessibilityNode(depth: depth, traits: Self.traits(of: element), label: label, value: value, hint: hint, identifier: Self.text(element.accessibilityIdentifier()), frame: frame)
			}

			/// The role in the iOS reader's words where there's a match (`button`, `text`), otherwise AppKit's without the `AX`.
			static func traits(of element: any NSAccessibilityProtocol) -> [String] {
				var traits: [String] = []
				if let role = element.accessibilityRole() { traits.append(roleNames[role] ?? String(role.rawValue.trimmingPrefix("AX"))) }
				if element.accessibilitySubrole() == .searchField { traits.append("searchField") }
				if element.isAccessibilitySelected() { traits.append("selected") }
				if !element.isAccessibilityEnabled() { traits.append("disabled") }
				return traits
			}

			static let roleNames: [NSAccessibility.Role: String] = [
				.button: "button", .link: "link", .image: "image", .staticText: "text", .checkBox: "toggle",
				.slider: "adjustable", .incrementor: "adjustable", .group: "group", .textField: "textField",
			]

			/// Non-empty text from a string, attributed string or number value.
			static func text(_ value: Any?) -> String? {
				let text = switch value {
				case let string as String: string
				case let attributed as NSAttributedString: attributed.string
				case let number as NSNumber: number.stringValue
				default: ""
				}
				return text.isEmpty ? nil : text
			}
		}
	}
#endif
