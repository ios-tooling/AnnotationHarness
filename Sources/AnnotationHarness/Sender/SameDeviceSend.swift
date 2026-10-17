#if DEBUG && os(iOS)
	import AnnotationCore
	import UIKit

	/// Hands a capture to a companion on this device. iOS suspends a companion in the background, so loopback networking
	/// to it can't be relied on: the envelope goes on the general pasteboard instead, and the companion is opened by URL.
	///
	/// UIKit on purpose: SwiftUI has no pasteboard API for a custom type, and no way to ask whether a URL can be opened.
	@MainActor enum SameDeviceSend {
		/// Whether the companion is installed here. Needs `annotationharness` in the host's `LSApplicationQueriesSchemes`.
		static var isAvailable: Bool {
			UIApplication.shared.canOpenURL(CompanionWire.receiveURL)
		}

		/// Replaces the pasteboard's contents, the user's clipboard included, with the encoded envelope.
		static func place(_ envelope: CaptureEnvelope) throws {
			UIPasteboard.general.setData(try envelope.encoded(), forPasteboardType: CompanionWire.pasteboardType)
		}
	}
#endif
