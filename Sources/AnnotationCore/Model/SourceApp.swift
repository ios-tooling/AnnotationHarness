import Foundation

/// The app a session's captures came from.
package struct SourceApp: Codable, Sendable, Equatable {
	package var name: String
	/// Empty when unknown, as in sessions written before the source was recorded.
	package var bundleID: String
	package var version: String
	package var build: String
	package var platform: Platform

	/// The platform the source app ran on.
	package enum Platform: String, Codable, Sendable {
		case iOS, macOS

		/// The platform this code is running on.
		package static var current: Platform {
			#if os(macOS)
				.macOS
			#else
				.iOS
			#endif
		}
	}

	package init(name: String, bundleID: String, version: String, build: String, platform: Platform) {
		self.name = name
		self.bundleID = bundleID
		self.version = version
		self.build = build
		self.platform = platform
	}

	/// The app described by `bundle`'s Info.plist, running on this platform.
	package init(bundle: Bundle = .main, platform: Platform = .current) {
		let info = bundle.infoDictionary ?? [:]
		let name = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? "App"
		self.init(name: name, bundleID: bundle.bundleIdentifier ?? "", version: info["CFBundleShortVersionString"] as? String ?? "?", build: info["CFBundleVersion"] as? String ?? "?", platform: platform)
	}
}
