#if DEBUG && os(iOS)
	import SwiftUI

	/// The harness's tools: capture, device choice, the session's captures and its export.
	struct HarnessInspectorView: View {
		@Bindable var session: HarnessSession
		@Binding var isPresenting: Bool
		let capture: () -> Void
		let share: (CGRect) -> Void
		let startNewSession: () -> Void
		@State private var confirmsNewSession = false
		@State private var shareButtonFrame: CGRect = .zero

		var body: some View {
			NavigationStack {
				List {
					Section {
						Button("Capture Screen", systemImage: "camera.viewfinder", action: capture)
							.font(.headline)
						Button("Share Report", systemImage: "square.and.arrow.up") { share(shareButtonFrame) }
							.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { shareButtonFrame = $0 }
							.disabled(session.captures.isEmpty)
					}
					Section("Device") {
						Picker("Layout", selection: $session.deviceID) {
							ForEach(DeviceProfile.all) { device in
								Text(device.name).tag(device.id)
							}
						}
					}
					Section {
						ForEach(session.captures) { capture in
							CaptureRowView(capture: capture, folder: session.folder)
						}
						.onDelete { offsets in
							offsets.map { session.captures[$0] }.forEach(session.delete)
						}
					} header: {
						Text("Captures")
					} footer: {
						if session.captures.isEmpty { Text("Captures you save appear here.") }
					}
				}
				.navigationTitle("Annotations")
				.toolbar {
					ToolbarItem(placement: .primaryAction) {
						Button("New Session", systemImage: "plus.square.on.square") { confirmsNewSession = true }
					}
				}
				// The phone window sits above the inspector's presentations, so it hides while the dialog is up.
				.onChange(of: confirmsNewSession) { isPresenting = confirmsNewSession }
				.confirmationDialog("Start a new session?", isPresented: $confirmsNewSession, titleVisibility: .visible) {
					Button("New Session", action: startNewSession)
					Button("Cancel", role: .cancel) {}
				} message: {
					Text("This session's captures stay on disk but leave the list and the next report.")
				}
			}
		}
	}

	struct CaptureRowView: View {
		let capture: Capture
		let folder: URL
		@ScaledMetric private var thumbnailHeight = 64

		var body: some View {
			HStack {
				AsyncImage(url: folder.appending(path: capture.annotatedPath)) { image in
					image.resizable().scaledToFit()
				} placeholder: {
					Color.secondary.opacity(0.2)
				}
				.frame(height: thumbnailHeight)
				VStack(alignment: .leading) {
					Text(capture.title).font(.headline)
					Text(capture.note.isEmpty ? "No note" : capture.note)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.lineLimit(2)
				}
			}
		}
	}
#endif
