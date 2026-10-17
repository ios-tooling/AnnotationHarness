import Foundation

/// One accessibility element (or labelled container) that was on screen when a capture was taken.
/// `frame` is in points from the top-left of the captured screen or window.
package struct AccessibilityNode: Codable, Sendable, Equatable {
	package var depth = 0
	package var traits: [String] = []
	package var label: String?
	package var value: String?
	package var hint: String?
	package var identifier: String?
	package var frame: CGRect = .zero

	package init(depth: Int = 0, traits: [String] = [], label: String? = nil, value: String? = nil, hint: String? = nil, identifier: String? = nil, frame: CGRect = .zero) {
		self.depth = depth
		self.traits = traits
		self.label = label
		self.value = value
		self.hint = hint
		self.identifier = identifier
		self.frame = frame
	}

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
