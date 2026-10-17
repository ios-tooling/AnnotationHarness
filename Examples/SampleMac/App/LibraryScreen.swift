import AnnotationHarness
import SwiftUI

/// The main window: a searchable list of books with a few actions.
struct LibraryScreen: View {
	@State private var search = ""
	@State private var selection: String?
	@Environment(\.openWindow) private var openWindow
	private let books = ["The Hobbit", "Dune", "Middlemarch", "Moby-Dick", "Beloved"]

	var body: some View {
		VStack(alignment: .leading) {
			TextField("Search books", text: $search)
				.textFieldStyle(.roundedBorder)
			List(books.filter { search.isEmpty || $0.localizedStandardContains(search) }, id: \.self, selection: $selection) { book in
				Text(book)
			}
			HStack {
				Button("Add Book") {}
				Button("Remove Book") {}
					.disabled(selection == nil)
				Spacer()
				Button("Show Inspector") { openWindow(id: SampleWindow.inspector.rawValue) }
			}
		}
		.padding()
		.toolbar {
			Button("Refresh", systemImage: "arrow.clockwise") {}
			Button("Share", systemImage: "square.and.arrow.up") {}
		}
		.navigationTitle("Library")
		.annotationScreen("Library")
	}
}
