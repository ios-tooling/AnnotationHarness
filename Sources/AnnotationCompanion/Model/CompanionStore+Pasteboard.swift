#if os(iOS)
	import AnnotationCore
	import UIKit

	extension CompanionStore {
		/// Handles `annotationharness://receive`, which a sender on this iPad opens after putting its envelope on the pasteboard.
		/// Returns whether the URL was one; anything else is ignored.
		package func open(_ url: URL) -> Bool {
			guard url.scheme == CompanionWire.urlScheme, url.host() == CompanionWire.receiveURL.host() else { return false }
			receiveFromPasteboard()
			return true
		}

		/// Reads the encoded envelope off the general pasteboard, files it in the inbox and clears the pasteboard.
		/// UIPasteboard has no SwiftUI equivalent for reading a custom type without user interaction.
		/// The sender wrote the envelope as the pasteboard's only contents, so clearing it all removes just that item;
		/// reading the other items to keep them would ask the user's permission again.
		private func receiveFromPasteboard() {
			let pasteboard = UIPasteboard.general
			guard let data = pasteboard.data(forPasteboardType: CompanionWire.pasteboardType) else {
				problem = "Nothing to receive: the pasteboard holds no capture."
				return
			}
			pasteboard.items = []
			do {
				try receive(CaptureEnvelope(decoding: data))
				problem = nil
			} catch {
				problem = "Couldn't read the capture on the pasteboard: \(error.localizedDescription)"
			}
		}
	}
#endif
