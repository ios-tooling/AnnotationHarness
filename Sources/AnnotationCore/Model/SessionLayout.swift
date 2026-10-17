import Foundation

extension SessionManifest {
	/// What the captures show, which sets the report's layout line and where frames are measured from.
	///
	/// Nested rather than top-level so it doesn't clash with SwiftUI's `Layout` in files that import both.
	package enum Layout: Codable, Sendable, Equatable {
		/// An iPhone layout run in the iPad harness, imitating the `DeviceProfile` with this ID.
		case harness(deviceID: String)
		/// A Mac app's window, title bar included.
		case macWindow(size: CGSize)
		/// A whole device screen.
		case screen(model: String, size: CGSize)

		/// The harness's device, or `nil` for other layouts.
		package var deviceID: String? {
			if case .harness(let deviceID) = self { return deviceID }
			return nil
		}
	}
}
