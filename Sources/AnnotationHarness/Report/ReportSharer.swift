#if DEBUG && os(iOS)
	import UIKit

	/// Presents the share sheet for a session's zip.
	///
	/// UIKit rather than `ShareLink`: the harness has to hide the phone window while the sheet is up
	/// (the phone window sits above it), and `ShareLink` gives no word of when its sheet opens or closes.
	@MainActor enum ReportSharer {
		static func share(_ archive: ReportArchive, from rect: CGRect, in window: UIWindow, onDismiss: @escaping @MainActor () -> Void) {
			guard let zip = try? archive.makeZip() else {
				onDismiss()
				return
			}
			let sheet = UIActivityViewController(activityItems: [zip], applicationActivities: nil)
			sheet.popoverPresentationController?.sourceView = window
			sheet.popoverPresentationController?.sourceRect = rect
			sheet.completionWithItemsHandler = { _, _, _, _ in
				Task { @MainActor in onDismiss() }
			}
			var presenter = window.rootViewController
			while let next = presenter?.presentedViewController { presenter = next }
			presenter?.present(sheet, animated: true)
		}
	}
#endif
