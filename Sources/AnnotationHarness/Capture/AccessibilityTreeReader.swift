#if DEBUG && os(iOS)
	import UIKit

	/// Walks the window's accessibility tree, the same one VoiceOver and UI tests see,
	/// and keeps the elements on the phone window's screen, in reading order.
	@MainActor enum AccessibilityTreeReader {
		static func nodes(in window: UIWindow) -> [AccessibilityNode] {
			var reader = Walk(window: window)
			reader.visit(window, depth: 0)
			return reader.nodes
		}

		@MainActor private struct Walk {
			let window: UIWindow
			var nodes: [AccessibilityNode] = []

			mutating func visit(_ object: NSObject, depth: Int) {
				if let view = object as? UIView, view.isHidden || view.alpha == 0 || view.accessibilityElementsHidden { return }
				if object.isAccessibilityElement {
					if let node = node(for: object, depth: depth) { nodes.append(node) }
					return
				}
				var childDepth = depth
				if object.accessibilityContainerType != .none, let label = object.accessibilityLabel, !label.isEmpty, var group = node(for: object, depth: depth) {
					group.traits = ["group"] + group.traits
					nodes.append(group)
					childDepth += 1
				}
				for child in children(of: object) { visit(child, depth: childDepth) }
			}

			func children(of object: NSObject) -> [NSObject] {
				if let elements = object.accessibilityElements as? [NSObject], !elements.isEmpty { return elements }
				let count = object.accessibilityElementCount()
				if count > 0, count != NSNotFound {
					return (0..<count).compactMap { object.accessibilityElement(at: $0) as? NSObject }
				}
				guard let view = object as? UIView else { return [] }
				// VoiceOver's rule: a modal view (a presented sheet's container, say) hides its siblings, so the screen behind a sheet isn't listed.
				if let modal = view.subviews.last(where: { $0.accessibilityViewIsModal && !$0.isHidden }) { return [modal] }
				return view.subviews
			}

			func node(for object: NSObject, depth: Int) -> AccessibilityNode? {
				// Screen coordinates into the window's own, which also undoes any fit-to-stage scaling.
				let local = window.convert(object.accessibilityFrame, from: window.screen.coordinateSpace)
				guard local.intersects(window.bounds) else { return nil }
				let identifier = (object as? UIAccessibilityIdentification)?.accessibilityIdentifier
				return AccessibilityNode(depth: depth, traits: object.accessibilityTraits.names, label: object.accessibilityLabel, value: object.accessibilityValue, hint: object.accessibilityHint, identifier: identifier, frame: local)
			}
		}
	}

	extension UIAccessibilityTraits {
		var names: [String] {
			let known: [(UIAccessibilityTraits, String)] = [
				(.button, "button"), (.link, "link"), (.header, "header"), (.searchField, "searchField"),
				(.image, "image"), (.selected, "selected"), (.staticText, "text"), (.adjustable, "adjustable"),
				(.toggleButton, "toggle"), (.tabBar, "tabBar"), (.notEnabled, "disabled"), (.keyboardKey, "key"),
			]
			return known.filter { contains($0.0) }.map(\.1)
		}
	}
#endif
