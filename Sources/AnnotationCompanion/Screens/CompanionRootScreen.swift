#if os(iOS)
	import SwiftUI

	/// The companion app's whole interface: source apps in the sidebar, the selected app's captures in the detail.
	/// It listens for captures while the scene is active and handles `annotationharness://receive` from senders on this iPad.
	public struct CompanionRootScreen: View {
		@State private var store = CompanionStore()
		@State private var selection: String?
		@State private var explainsPastePermission = false
		@AppStorage("explainedPastePermission") private var explainedPastePermission = false
		@Environment(\.scenePhase) private var scenePhase

		public init() {}

		public var body: some View {
			NavigationSplitView {
				SourceAppList(apps: store.apps, selection: $selection)
			} detail: {
				if let app = store.apps.first(where: { $0.key == selection }) {
					SourceAppScreen(app: app, store: store)
				} else {
					WaitingForCapturesView(advertisedName: store.advertisedName, problem: store.problem)
				}
			}
			.onChange(of: store.apps.map(\.key), initial: true) { _, keys in
				if selection.map(keys.contains) != true { selection = keys.first }
			}
			.onChange(of: scenePhase, initial: true) { _, phase in
				switch phase {
				case .active: store.startListening()
				case .background: store.stopListening()
				default: break
				}
			}
			.onOpenURL { url in
				guard store.open(url), !explainedPastePermission else { return }
				explainedPastePermission = true
				explainsPastePermission = true
			}
			.alert("Allow Pasting from Other Apps", isPresented: $explainsPastePermission) {
				Button("OK") {}
			} message: {
				Text("Apps on this iPad send captures through the pasteboard. So iOS doesn't ask every time, open Settings › AnnotationHarness Companion › Paste from Other Apps and choose Allow.")
			}
		}
	}
#endif
