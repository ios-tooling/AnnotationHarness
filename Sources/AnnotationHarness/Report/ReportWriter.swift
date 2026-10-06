#if DEBUG
	import Foundation

	/// Builds `report.md`: a Markdown report a coding agent can read, one section per capture.
	enum ReportWriter {
		static func markdown(for manifest: SessionManifest) -> String {
			let device = manifest.device
			var lines = [
				"# \(manifest.appName) annotation report",
				"",
				"- App: \(manifest.appName) \(manifest.appVersion) (\(manifest.build))",
				"- Session started: \(manifest.started.formatted(.iso8601))",
				"- Layout: \(device.name), \(Int(device.size.width))×\(Int(device.size.height)) pt, run in AnnotationHarness on an iPad (its own iPhone-sized window with compact size classes; the status bar is drawn by the harness and the keyboard is the iPad's)",
				"- Captures: \(manifest.captures.count)",
				"",
				"Each capture shows the screen with the tester's markup, links the unmarked original, and lists the accessibility elements that were on screen. Frames are in points from the top-left of the iPhone screen.",
			]
			for capture in manifest.captures {
				lines += section(for: capture)
			}
			return lines.joined(separator: "\n") + "\n"
		}

		static func section(for capture: Capture) -> [String] {
			var lines = [
				"",
				"## \(capture.number). \(capture.title)",
				"",
				"![\(capture.title), annotated](\(capture.annotatedPath))",
				"",
				"Original: [\(capture.originalPath)](\(capture.originalPath)) · \(capture.date.formatted(.iso8601))",
				"",
				"### Note",
				"",
			]
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
#endif
