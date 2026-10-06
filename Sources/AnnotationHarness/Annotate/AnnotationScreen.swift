#if DEBUG && os(iOS)
	import PencilKit
	import SwiftUI

	/// Marks up a fresh capture with the Pencil and adds a note, then saves both into the session.
	struct AnnotationScreen: View {
		let draft: CaptureDraft
		let session: HarnessSession
		@Environment(\.dismiss) private var dismiss
		@State private var drawing = PKDrawing()
		@State private var canvasSize: CGSize = .zero
		@State private var note = ""
		@State private var screenName: String
		@State private var saveError: String?

		init(draft: CaptureDraft, session: HarnessSession) {
			self.draft = draft
			self.session = session
			_screenName = State(initialValue: draft.screenName ?? "")
		}

		var body: some View {
			NavigationStack {
				AnnotationCanvasView(image: draft.image, drawing: $drawing, canvasSize: $canvasSize)
					.inspector(isPresented: .constant(true)) {
						Form {
							Section("Screen") {
								TextField("Screen name", text: $screenName)
							}
							Section("Note") {
								TextField("What should change?", text: $note, axis: .vertical)
									.lineLimit(4...)
							}
							Section {
								LabeledContent("Accessibility elements", value: draft.accessibility.count, format: .number)
							} footer: {
								if let saveError { Text(saveError).foregroundStyle(.red) }
							}
						}
					}
					.navigationTitle("Annotate")
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							Button("Discard", role: .cancel) { dismiss() }
						}
						ToolbarItem(placement: .confirmationAction) {
							Button("Save", action: save)
						}
					}
			}
		}

		private func save() {
			let annotated = ImageCompositor.annotated(draft.image, drawing: drawing, canvasSize: canvasSize)
			guard let original = draft.image.pngData(), let marked = annotated.pngData() else {
				saveError = "Couldn't encode the screenshot."
				return
			}
			do {
				let name = screenName.trimmingCharacters(in: .whitespacesAndNewlines)
				try session.add(original: original, annotated: marked, note: note, screenName: name.isEmpty ? nil : name, accessibility: draft.accessibility)
				dismiss()
			} catch {
				saveError = error.localizedDescription
			}
		}
	}

	/// The screenshot at no more than its real size, with the Pencil canvas laid exactly over it.
	struct AnnotationCanvasView: View {
		let image: UIImage
		@Binding var drawing: PKDrawing
		@Binding var canvasSize: CGSize

		var body: some View {
			Image(uiImage: image)
				.resizable()
				.scaledToFit()
				.frame(maxWidth: image.size.width, maxHeight: image.size.height)
				.overlay {
					PencilCanvas(drawing: $drawing)
						.onGeometryChange(for: CGSize.self) { $0.size } action: { canvasSize = $0 }
				}
				.overlay { Rectangle().strokeBorder(.separator) }
				.padding()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.background(.background.secondary)
		}
	}
#endif
