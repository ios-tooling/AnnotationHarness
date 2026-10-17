#if os(iOS)
	import SwiftUI

	/// The empty state: nothing has arrived yet, so it says which target to pick in the sending app.
	struct WaitingForCapturesView: View {
		let advertisedName: String?
		let problem: String?

		var body: some View {
			ContentUnavailableView {
				Label("Waiting for captures", systemImage: "tray")
			} description: {
				if let problem {
					Text(problem)
				} else if let advertisedName {
					Text("In the app you're sending from, choose “\(advertisedName)” as the target.")
				} else {
					Text("Getting ready to receive…")
				}
			}
		}
	}
#endif
