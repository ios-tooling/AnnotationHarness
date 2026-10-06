#if DEBUG
	import Foundation

	/// One accessibility element (or labelled container) that was on screen when a capture was taken.
	/// `frame` is in points from the top-left of the imitated iPhone screen.
	struct AccessibilityNode: Codable, Sendable, Equatable {
		var depth = 0
		var traits: [String] = []
		var label: String?
		var value: String?
		var hint: String?
		var identifier: String?
		var frame: CGRect = .zero

		/// A single report line, e.g. `- button "Save" #save-button (16, 812, 370×44)`.
		var line: String {
			var parts = [traits.isEmpty ? "element" : traits.joined(separator: "/")]
			if let label, !label.isEmpty { parts.append("\"\(label)\"") }
			if let value, !value.isEmpty { parts.append("= \"\(value)\"") }
			if let identifier, !identifier.isEmpty { parts.append("#\(identifier)") }
			if let hint, !hint.isEmpty { parts.append("(hint: \(hint))") }
			parts.append("(\(Int(frame.minX)), \(Int(frame.minY)), \(Int(frame.width))×\(Int(frame.height)))")
			return String(repeating: "  ", count: depth) + "- " + parts.joined(separator: " ")
		}
	}
#endif
