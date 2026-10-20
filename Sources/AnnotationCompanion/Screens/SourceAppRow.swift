#if os(iOS)
	import SwiftUI

	/// A source app in the sidebar. Swiping it offers Delete, which asks first since saved annotations go with it.
	/// The dialog hangs off the row, so on iPad its popover points at the app being deleted.
	struct SourceAppRow: View {
		let app: CompanionApp
		let store: CompanionStore
		@Binding var selection: String?
		@State private var savedCount: Int?

		var body: some View {
			Label(app.source.name, systemImage: app.source.platform.symbolName)
				.badge(app.waiting.count)
				.swipeActions {
					// Red by tint, not `role: .destructive`: that role makes the List drop the row straight away,
					// before the user has confirmed, and the dialog that hangs off it goes too.
					Button("Delete", systemImage: "trash") { savedCount = store.savedCaptureCount(for: app) }
						.tint(.red)
				}
				.confirmationDialog("Delete “\(app.source.name)”?", isPresented: confirms, titleVisibility: .visible) {
					Button("Delete", role: .destructive, action: delete)
					Button("Cancel", role: .cancel) {}
				} message: {
					Text("This deletes ^[\(app.waiting.count) waiting capture](inflect: true) and ^[\(savedCount ?? 0) saved capture](inflect: true), and can't be undone.")
				}
		}

		private var confirms: Binding<Bool> {
			Binding { savedCount != nil } set: { if !$0 { savedCount = nil } }
		}

		/// Deletes the app; if it was selected, the app after it (or else before it) is selected instead.
		private func delete() {
			if selection == app.key {
				let apps = store.apps
				let rest = apps.filter { $0.key != app.key }
				let index = apps.firstIndex { $0.key == app.key } ?? 0
				selection = rest.isEmpty ? nil : rest[min(index, rest.count - 1)].key
			}
			store.removeApp(app)
		}
	}
#endif
