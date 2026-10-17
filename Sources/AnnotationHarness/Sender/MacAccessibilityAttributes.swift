#if DEBUG && os(macOS)
	import AppKit
	import ApplicationServices

	/// One element's attributes, read through the accessibility client API in a single call.
	struct MacAccessibilityAttributes {
		private static let names = [
			kAXRoleAttribute, kAXSubroleAttribute, kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute, kAXHelpAttribute,
			kAXIdentifierAttribute, kAXPlaceholderValueAttribute, kAXPositionAttribute, kAXSizeAttribute, kAXEnabledAttribute, kAXSelectedAttribute,
		]
		private var values: [String: AnyObject] = [:]

		init(_ element: AXUIElement) {
			var list: CFArray?
			guard AXUIElementCopyMultipleAttributeValues(element, Self.names as CFArray, [], &list) == .success, let list = list as? [AnyObject] else { return }
			// An attribute the element doesn't have comes back as an error value in its place.
			for (name, value) in zip(Self.names, list) where !Self.isError(value) { values[name] = value }
		}

		var role: NSAccessibility.Role? { (values[kAXRoleAttribute] as? String).map { NSAccessibility.Role(rawValue: $0) } }
		var subrole: NSAccessibility.Subrole? { (values[kAXSubroleAttribute] as? String).map { NSAccessibility.Subrole(rawValue: $0) } }
		var title: String? { Self.text(values[kAXTitleAttribute]) }
		var description: String? { Self.text(values[kAXDescriptionAttribute]) }
		var value: String? { Self.text(values[kAXValueAttribute]) }
		var help: String? { Self.text(values[kAXHelpAttribute]) }
		var identifier: String? { Self.text(values[kAXIdentifierAttribute]) }
		var placeholder: String? { Self.text(values[kAXPlaceholderValueAttribute]) }
		var isEnabled: Bool { (values[kAXEnabledAttribute] as? Bool) ?? true }
		var isSelected: Bool { (values[kAXSelectedAttribute] as? Bool) ?? false }

		/// In the accessibility API's screen coordinates: points from the top-left of the main display.
		var frame: CGRect? {
			var origin = CGPoint.zero, size = CGSize.zero
			guard let position = Self.axValue(values[kAXPositionAttribute]), let extent = Self.axValue(values[kAXSizeAttribute]) else { return nil }
			guard AXValueGetValue(position, .cgPoint, &origin), AXValueGetValue(extent, .cgSize, &size) else { return nil }
			return CGRect(origin: origin, size: size)
		}

		private static func axValue(_ value: AnyObject?) -> AXValue? {
			guard let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
			return (value as! AXValue)
		}

		private static func isError(_ value: AnyObject) -> Bool {
			axValue(value).map { AXValueGetType($0) == .axError } ?? false
		}

		/// Non-empty text from a string, attributed string or number value.
		private static func text(_ value: AnyObject?) -> String? {
			let text = switch value {
			case let string as String: string
			case let attributed as NSAttributedString: attributed.string
			case let number as NSNumber: number.stringValue
			default: ""
			}
			return text.isEmpty ? nil : text
		}
	}

	extension AXUIElement {
		/// The elements an attribute holds, such as `kAXChildrenAttribute` or `kAXWindowsAttribute`.
		func elements(_ attribute: String) -> [AXUIElement] {
			var value: CFTypeRef?
			guard AXUIElementCopyAttributeValue(self, attribute as CFString, &value) == .success else { return [] }
			return value as? [AXUIElement] ?? []
		}
	}
#endif
