#if DEBUG && os(iOS)
	import AnnotationCore
	import UIKit

	/// Captures the app's window for the companion: the phone window while the iPad harness runs,
	/// otherwise the key window of the foreground scene.
	@MainActor enum WindowCapture {
		/// Whether a companion is installed on this device, for when none is found on the network.
		static var sameDeviceAvailable: Bool { SameDeviceSend.isAvailable }

		static func envelope(screenName: String?) -> CaptureEnvelope? {
			if let stage = StageGeometry.current, let window = stage.window, let deviceID = stage.deviceID {
				return envelope(of: window, layout: .harness(deviceID: deviceID), screenName: stage.screenName)
			}
			guard let window = keyWindow else { return nil }
			return envelope(of: window, layout: .screen(model: hardwareModel, size: window.bounds.size), screenName: screenName)
		}

		/// The window at full resolution, with its accessibility elements, the same way the harness captures.
		static func envelope(of window: UIWindow, layout: SessionManifest.Layout, screenName: String?) -> CaptureEnvelope? {
			AccessibilityActivation.activate()
			let image = CaptureSnapshotter.snapshot(of: window)
			guard let png = image.pngData() else { return nil }
			return CaptureEnvelope(source: SourceApp(bundle: .main), layout: layout, screenName: screenName, accessibility: AccessibilityTreeReader.nodes(in: window), imageScale: image.scale, png: png)
		}

		private static var keyWindow: UIWindow? {
			let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
			return scenes.first { $0.activationState == .foregroundActive }?.keyWindow
		}

		/// The hardware identifier, such as `iPhone17,1`; in the simulator, the one it simulates.
		private static var hardwareModel: String {
			if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
			var system = utsname()
			uname(&system)
			return withUnsafeBytes(of: system.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
		}
	}
#endif
