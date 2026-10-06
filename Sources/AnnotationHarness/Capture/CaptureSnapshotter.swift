#if DEBUG && os(iOS)
	import SwiftUI
	import UIKit

	/// A screenshot waiting to be marked up.
	struct CaptureDraft: Identifiable {
		let id = UUID()
		let image: UIImage
		let accessibility: [AccessibilityNode]
		let screenName: String?
	}

	/// Captures the phone window.
	///
	/// This is UIKit on purpose: SwiftUI's `ImageRenderer` can't render a live hierarchy
	/// (lists, text fields and other platform-backed views come out blank), so the window is snapshotted instead.
	@MainActor enum CaptureSnapshotter {
		static func draft(of window: UIWindow, screenName: String?) -> CaptureDraft {
			CaptureDraft(image: snapshot(of: window), accessibility: AccessibilityTreeReader.nodes(in: window), screenName: screenName)
		}

		/// Renders the window at full resolution in its own coordinates, so any fit-to-stage scaling is left out.
		static func snapshot(of window: UIWindow) -> UIImage {
			let format = UIGraphicsImageRendererFormat()
			format.scale = window.traitCollection.displayScale
			return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
				window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
			}
		}
	}
#endif
