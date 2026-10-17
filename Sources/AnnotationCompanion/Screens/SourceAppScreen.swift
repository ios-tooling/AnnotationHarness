#if os(iOS)
	import AnnotationCore
	import AnnotationUI
	import SwiftUI

	/// One source app: its captures waiting to be annotated, the ones saved in its session, and the session's report.
	struct SourceAppScreen: View {
		let app: CompanionApp
		let store: CompanionStore
		@State private var annotating: Annotation?

		private var session: HarnessSession? { store.sessions[app.key] }

		var body: some View {
			List {
				Section {
					ForEach(app.waiting) { item in
						Button { annotate(item) } label: { WaitingCaptureRow(item: item) }
							.buttonStyle(.plain)
					}
					.onDelete { offsets in
						offsets.map { app.waiting[$0] }.forEach(store.remove)
					}
				} header: {
					Text("Waiting")
				} footer: {
					if app.waiting.isEmpty { WaitingFooter(advertisedName: store.advertisedName) }
				}
				Section {
					ForEach(session?.captures ?? []) { capture in
						SavedCaptureRow(capture: capture, folder: session?.folder)
					}
				} header: {
					Text("Saved")
				} footer: {
					if session?.captures.isEmpty != false { Text("Captures you save appear here.") }
				}
			}
			.navigationTitle(app.source.name)
			.toolbar {
				ToolbarItemGroup(placement: .primaryAction) {
					ReportShareButton(appName: app.source.name, session: session)
					NewSessionButton { store.startNewSession(for: app) }
				}
			}
			.fullScreenCover(item: $annotating) { annotation in
				AnnotationScreen(draft: annotation.draft, session: annotation.session) { store.remove(annotation.item) }
			}
		}

		/// Opens the markup screen on a waiting capture; Save files it in the app's session and takes it out of the inbox, Discard leaves it waiting.
		private func annotate(_ item: InboxItem) {
			guard let data = try? Data(contentsOf: item.imageURL), let image = UIImage(data: data, scale: item.envelope.imageScale) else { return }
			let draft = CaptureDraft(image: image, accessibility: item.envelope.accessibility, screenName: item.envelope.screenName, layout: item.envelope.layout, date: item.envelope.date)
			annotating = Annotation(item: item, draft: draft, session: store.session(for: item))
		}
	}

	/// A waiting capture being marked up, and the session it saves into.
	struct Annotation: Identifiable {
		let item: InboxItem
		let draft: CaptureDraft
		let session: HarnessSession

		var id: UUID { item.id }
	}

	/// Under an empty Waiting section: which target to pick to send more.
	struct WaitingFooter: View {
		let advertisedName: String?

		var body: some View {
			if let advertisedName {
				Text("Waiting for captures. In the app you're sending from, choose “\(advertisedName)”.")
			} else {
				Text("Waiting for captures.")
			}
		}
	}
#endif
