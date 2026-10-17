#if os(iOS)
	import AnnotationCore
	import CoreTransferable
	import SwiftUI
	import UniformTypeIdentifiers

	/// Shares the session's report as a zip, made only when the user picks a destination.
	/// `ShareLink` rather than `ReportSharer`: the companion has no phone window to hide while the sheet is up.
	struct ReportShareButton: View {
		let appName: String
		let session: HarnessSession?

		var body: some View {
			if let session {
				ShareLink(item: ReportFile(archive: session.archive), preview: SharePreview("\(appName) report")) {
					Label("Share Report", systemImage: "square.and.arrow.up")
				}
				.disabled(session.captures.isEmpty)
			} else {
				Button("Share Report", systemImage: "square.and.arrow.up") {}
					.disabled(true)
			}
		}
	}

	/// A session's report, zipped lazily by `ReportArchive.makeZip()` when it's shared.
	struct ReportFile: Transferable {
		let archive: ReportArchive

		static var transferRepresentation: some TransferRepresentation {
			FileRepresentation(exportedContentType: .zip) { file in
				SentTransferredFile(try file.archive.makeZip())
			}
		}
	}
#endif
