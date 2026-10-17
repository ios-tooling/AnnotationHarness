import Foundation

/// A session folder, shared as a single zip.
package struct ReportArchive: Sendable {
	package let folder: URL
	package let name: String

	/// Zips the folder with the system's own archiver (`NSFileCoordinator`'s `.forUploading`).
	package func makeZip() throws -> URL {
		let destination = URL.temporaryDirectory.appending(path: "\(name).zip")
		var coordinatorError: NSError?
		var copyError: Error?
		NSFileCoordinator().coordinate(readingItemAt: folder, options: .forUploading, error: &coordinatorError) { zipURL in
			do {
				try? FileManager.default.removeItem(at: destination)
				try FileManager.default.copyItem(at: zipURL, to: destination)
			} catch {
				copyError = error
			}
		}
		if let error = coordinatorError ?? copyError { throw error }
		return destination
	}
}
