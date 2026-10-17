import AnnotationHarness
import SwiftUI

/// A small utility window: details of the selected book.
struct InspectorScreen: View {
	@State private var title = "Dune"
	@State private var isFavorite = true
	@State private var rating = 4.0

	var body: some View {
		Form {
			TextField("Title", text: $title)
			Toggle("Favorite", isOn: $isFavorite)
			Slider(value: $rating, in: 0...5, step: 1) { Text("Rating") }
			LabeledContent("Pages", value: "412")
			Button("Save Changes") {}
		}
		.padding()
		.annotationScreen("Inspector")
	}
}
