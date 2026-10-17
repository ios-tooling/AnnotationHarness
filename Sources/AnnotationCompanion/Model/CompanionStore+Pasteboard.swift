#if os(iOS)
	import AnnotationCore
	import UIKit

	/// What came of a sender's `annotationharness://receive`.
	package enum PasteboardReceipt {
		case received
		/// The pasteboard gave nothing back, which for a sender that just wrote to it means the user didn't allow the paste.
		case denied
		case unreadable
	}

	extension CompanionStore {
		/// Handles `annotationharness://receive`, which a sender on this iPad opens after putting its envelope on the pasteboard.
		/// Returns what came of it, or `nil` for any other URL, which is ignored.
		package func open(_ url: URL) -> PasteboardReceipt? {
			guard url.scheme == CompanionWire.urlScheme, url.host() == CompanionWire.receiveURL.host() else { return nil }
			return receiveFromPasteboard()
		}

		/// Reads the encoded envelope off the general pasteboard, files it in the inbox and clears the pasteboard.
		/// UIPasteboard has no SwiftUI equivalent for reading a custom type without user interaction.
		/// The sender wrote the envelope as the pasteboard's only contents, so clearing it all removes just that item;
		/// reading the other items to keep them would ask the user's permission again.
		private func receiveFromPasteboard() -> PasteboardReceipt {
			let pasteboard = UIPasteboard.general
			guard let data = pasteboard.data(forPasteboardType: CompanionWire.pasteboardType) else {
				problem = "Nothing received: pasting from the sending app wasn't allowed, or the pasteboard holds no capture."
				return .denied
			}
			pasteboard.items = []
			do {
				try receive(CaptureEnvelope(decoding: data))
				problem = nil
				return .received
			} catch {
				problem = "Couldn't read the capture on the pasteboard: \(error.localizedDescription)"
				return .unreadable
			}
		}
	}
#endif
