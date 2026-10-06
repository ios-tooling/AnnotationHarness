#if DEBUG && os(iOS)
	import PencilKit
	import SwiftUI

	/// PencilKit's canvas and tool picker. PencilKit has no SwiftUI canvas, and its ink, eraser,
	/// lasso and undo are what make markup quick, so this wraps the UIKit view.
	struct PencilCanvas: UIViewRepresentable {
		@Binding var drawing: PKDrawing

		func makeCoordinator() -> Coordinator { Coordinator(drawing: $drawing) }

		func makeUIView(context: Context) -> PKCanvasView {
			let canvas = PKCanvasView()
			canvas.drawing = drawing
			canvas.backgroundColor = .clear
			canvas.isOpaque = false
			canvas.drawingPolicy = .anyInput
			canvas.delegate = context.coordinator

			let picker = context.coordinator.toolPicker
			picker.setVisible(true, forFirstResponder: canvas)
			picker.addObserver(canvas)
			Task { canvas.becomeFirstResponder() }
			return canvas
		}

		func updateUIView(_ canvas: PKCanvasView, context: Context) {
			if canvas.drawing != drawing { canvas.drawing = drawing }
		}

		@MainActor final class Coordinator: NSObject, PKCanvasViewDelegate {
			let toolPicker: PKToolPicker = {
				// Red pen first, so markup stands out on light and dark screens alike.
				let pen = PKToolPickerInkingItem(type: .pen, color: .systemRed)
				let picker = PKToolPicker(toolItems: [pen, PKToolPickerInkingItem(type: .marker, color: .systemYellow), PKToolPickerEraserItem(type: .vector), PKToolPickerLassoItem(), PKToolPickerRulerItem()])
				picker.selectedToolItem = pen
				return picker
			}()
			let drawing: Binding<PKDrawing>

			init(drawing: Binding<PKDrawing>) {
				self.drawing = drawing
			}

			func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
				drawing.wrappedValue = canvasView.drawing
			}
		}
	}

	/// Flattens the markup onto the screenshot at the screenshot's own resolution.
	@MainActor enum ImageCompositor {
		static func annotated(_ image: UIImage, drawing: PKDrawing, canvasSize: CGSize) -> UIImage {
			guard !drawing.strokes.isEmpty, canvasSize.width > 0 else { return image }
			let scale = image.size.width / canvasSize.width
			let markup = drawing.transformed(using: CGAffineTransform(scaleX: scale, y: scale))
			let bounds = CGRect(origin: .zero, size: image.size)
			let format = UIGraphicsImageRendererFormat()
			format.scale = image.scale
			return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
				image.draw(in: bounds)
				markup.image(from: bounds, scale: image.scale).draw(in: bounds)
			}
		}
	}
#endif
