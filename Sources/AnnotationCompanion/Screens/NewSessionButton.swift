#if os(iOS)
	import SwiftUI

	/// Starts a new session after asking. The dialog hangs off this button, not the screen:
	/// on the screen it also became the anchor for the Share Report popover, which then pointed at the middle of the column.
	struct NewSessionButton: View {
		let startNewSession: () -> Void
		@State private var confirms = false

		var body: some View {
			Button("New Session", systemImage: "plus.square.on.square") { confirms = true }
				.confirmationDialog("Start a new session?", isPresented: $confirms, titleVisibility: .visible) {
					Button("New Session", action: startNewSession)
					Button("Cancel", role: .cancel) {}
				} message: {
					Text("This session's captures stay on disk but leave the list and the next report.")
				}
		}
	}
#endif
