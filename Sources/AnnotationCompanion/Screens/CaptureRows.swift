#if os(iOS)
	import AnnotationCore
	import SwiftUI

	/// A capture in the inbox: its screenshot, screen name and when it was sent.
	struct WaitingCaptureRow: View {
		let item: InboxItem

		var body: some View {
			HStack {
				CaptureThumbnail(url: item.imageURL)
				VStack(alignment: .leading) {
					Text(item.envelope.screenName ?? "Untitled screen").font(.headline)
					Text(item.envelope.date, format: .dateTime.month().day().hour().minute())
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.contentShape(.rect)
		}
	}

	/// A capture saved in the session: the annotated screenshot, its title and note.
	struct SavedCaptureRow: View {
		let capture: Capture
		let folder: URL?

		var body: some View {
			HStack {
				CaptureThumbnail(url: folder?.appending(path: capture.annotatedPath))
				VStack(alignment: .leading) {
					Text("\(capture.number). \(capture.title)").font(.headline)
					Text(capture.note.isEmpty ? "No note" : capture.note)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.lineLimit(2)
				}
			}
		}
	}

	/// A screenshot on disk, scaled to fit a square slot that grows with Dynamic Type,
	/// so tall phone and wide Mac screenshots take the same room and the rows' titles line up.
	struct CaptureThumbnail: View {
		let url: URL?
		@ScaledMetric private var side = 96

		var body: some View {
			AsyncImage(url: url) { image in
				image.resizable().scaledToFit()
			} placeholder: {
				Color.secondary.opacity(0.2)
			}
			.frame(width: side, height: side)
		}
	}
#endif
