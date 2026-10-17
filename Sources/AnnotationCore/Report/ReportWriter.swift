import Foundation

/// Builds `report.md`: a Markdown report a coding agent can read, one section per capture.
enum ReportWriter {
	static func markdown(for manifest: SessionManifest) -> String {
		let source = manifest.source
		var lines = [
			"# \(source.name) annotation report",
			"",
			"- App: \(appLine(for: source))",
			"- Session started: \(manifest.started.formatted(.iso8601))",
			"- Layout: \(layoutLine(for: manifest))",
			"- Captures: \(manifest.captures.count)",
			"",
			"Each capture shows the screen with the tester's markup, links the unmarked original, and lists the accessibility elements that were on screen. Frames are in points from the top-left of the \(frameOrigin(for: manifest.layout)).",
		]
		for capture in manifest.captures {
			lines += section(for: capture, sessionLayout: manifest.layout)
		}
		return lines.joined(separator: "\n") + "\n"
	}

	/// The name, version and build, then the bundle ID when it's known and the platform.
	static func appLine(for source: SourceApp) -> String {
		var parts = ["\(source.name) \(source.version) (\(source.build))"]
		if !source.bundleID.isEmpty { parts.append(source.bundleID) }
		parts.append(source.platform.rawValue)
		return parts.joined(separator: ", ")
	}

	static func layoutLine(for manifest: SessionManifest) -> String {
		layoutLine(for: manifest.layout)
	}

	static func layoutLine(for layout: SessionManifest.Layout) -> String {
		switch layout {
		case .harness(let deviceID):
			let device = DeviceProfile.named(deviceID)
			return "\(device.name), \(Int(device.size.width))×\(Int(device.size.height)) pt, run in AnnotationHarness on an iPad (its own iPhone-sized window with compact size classes; the status bar is drawn by the harness and the keyboard is the iPad's)"
		case .macWindow(let size):
			return "Mac window, \(Int(size.width))×\(Int(size.height)) pt"
		case .screen(let model, let size):
			return "\(model), \(Int(size.width))×\(Int(size.height)) pt"
		}
	}

	static func frameOrigin(for layout: SessionManifest.Layout) -> String {
		switch layout {
		case .harness: "iPhone screen"
		case .macWindow: "window"
		case .screen: "screen"
		}
	}

	/// A capture's section; it gets its own "Layout:" line when its layout differs from `sessionLayout`.
	static func section(for capture: Capture, sessionLayout: SessionManifest.Layout? = nil) -> [String] {
		var lines = [
			"",
			"## \(capture.number). \(capture.title)",
			"",
			"![\(capture.title), annotated](\(capture.annotatedPath))",
			"",
			"Original: [\(capture.originalPath)](\(capture.originalPath)) · \(capture.date.formatted(.iso8601))",
			"",
		]
		if let layout = capture.layout, layout != sessionLayout {
			lines += ["Layout: \(layoutLine(for: layout))", ""]
		}
		lines += ["### Note", ""]
		let note = capture.note.trimmingCharacters(in: .whitespacesAndNewlines)
		lines.append(note.isEmpty ? "_No note._" : note)
		lines += ["", "### Accessibility elements", ""]
		if capture.accessibility.isEmpty {
			lines.append("_None found._")
		} else {
			lines.append("```")
			lines += capture.accessibility.map(\.line)
			lines.append("```")
		}
		return lines
	}
}
