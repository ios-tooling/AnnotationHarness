#if os(iOS)
	import AnnotationCore
	import SwiftUI

	/// The sidebar: one row per source app, with how many captures it has waiting.
	struct SourceAppList: View {
		let apps: [CompanionApp]
		@Binding var selection: String?

		var body: some View {
			List(apps, selection: $selection) { app in
				Label(app.source.name, systemImage: app.source.platform.symbolName)
					.badge(app.waiting.count)
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
