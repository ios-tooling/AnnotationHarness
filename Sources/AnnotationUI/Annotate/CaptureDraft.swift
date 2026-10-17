#if os(iOS)
	import AnnotationCore
	import UIKit

	/// A screenshot waiting to be marked up.
	package struct CaptureDraft: Identifiable {
		package let id = UUID()
		package let image: UIImage
		package let accessibility: [AccessibilityNode]
		package let screenName: String?
		/// What the screenshot shows, saved with the capture; `nil` for the harness, whose captures share the session's layout.
		package let layout: SessionManifest.Layout?
		/// When the screenshot was taken: the envelope's date for a sent capture, else when the draft was made.
		package let date: Date

		package init(image: UIImage, accessibility: [AccessibilityNode], screenName: String?, layout: SessionManifest.Layout? = nil, date: Date = .now) {
			self.image = image
			self.accessibility = accessibility
			self.screenName = screenName
			self.layout = layout
			self.date = date
		}
	}
#endif
