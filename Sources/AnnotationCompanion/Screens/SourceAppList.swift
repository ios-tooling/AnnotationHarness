#if os(iOS)
	import AnnotationCore
	import SwiftUI

	/// The sidebar: one row per source app, with how many captures it has waiting. Swiping a row deletes the app after asking.
	struct SourceAppList: View {
		let apps: [CompanionApp]
		let store: CompanionStore
		@Binding var selection: String?

		var body: some View {
			List(apps, selection: $selection) { app in
				SourceAppRow(app: app, store: store, selection: $selection)
			}
			.navigationTitle("Apps")
		}
	}

	extension SourceApp.Platform {
		/// The SF Symbol for the kind of device the app ran on.
		var symbolName: String {
			switch self {
			case .iOS: "iphone"
			case .macOS: "laptopcomputer"
			}
		}
	}
#endif
