#if DEBUG && os(iOS)
	import SwiftUI
	import UIKit

	/// An empty view on the stage that owns the phone window and keeps it over the stage's device frame.
	final class PhoneWindowAnchor<Root: View>: UIView {
		private(set) var phoneWindow: UIWindow?
		private var host: PhoneHostingController<Root>?
		private var device = DeviceProfile.standard
		private var frameInWindow: CGRect = .zero
		private var scale: CGFloat = 1
		private var hidesWindow = false
		private weak var stage: StageGeometry?

		func update(root: Root, device: DeviceProfile, frame: CGRect, scale: CGFloat, isHidden: Bool, stage: StageGeometry) {
			self.stage = stage
			self.device = device
			frameInWindow = frame
			self.scale = scale
			hidesWindow = isHidden
			if let host {
				host.rootView = root
			} else {
				host = Self.makeHost(root)
			}
			layoutPhoneWindow()
		}

		override func didMoveToWindow() {
			super.didMoveToWindow()
			layoutPhoneWindow()
		}

		func tearDown() {
			phoneWindow?.isHidden = true
			phoneWindow = nil
		}

		private func layoutPhoneWindow() {
			guard let scene = window?.windowScene, let host, frameInWindow.width > 0 else {
				phoneWindow?.isHidden = true
				return
			}
			let phone = phoneWindow ?? makeWindow(in: scene, root: host)
			let insets = device.safeArea
			host.deviceSafeArea = UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing)
			phone.transform = .identity
			phone.bounds = CGRect(origin: .zero, size: device.size)
			phone.center = CGPoint(x: frameInWindow.midX, y: frameInWindow.midY)
			phone.transform = CGAffineTransform(scaleX: scale, y: scale)
			phone.layer.cornerRadius = device.cornerRadius
			phone.isHidden = hidesWindow
		}

		private func makeWindow(in scene: UIWindowScene, root: UIViewController) -> UIWindow {
			let phone = UIWindow(windowScene: scene)
			phone.rootViewController = root
			phone.clipsToBounds = true
			phone.layer.borderWidth = 1 / traitCollection.displayScale
			phone.layer.borderColor = UIColor.separator.cgColor
			phoneWindow = phone
			stage?.window = phone
			stage?.hostWindow = window
			return phone
		}

		private static func makeHost(_ root: Root) -> PhoneHostingController<Root> {
			let host = PhoneHostingController(rootView: root)
			host.traitOverrides.horizontalSizeClass = .compact
			host.traitOverrides.verticalSizeClass = .regular
			host.view.backgroundColor = .systemBackground
			return host
		}
	}

	/// The phone window's root, whose content gets exactly the iPhone's safe area. As a window's root it
	/// already inherits the iPad's status bar inset, so only the difference is added on top.
	final class PhoneHostingController<Root: View>: UIHostingController<Root> {
		var deviceSafeArea: UIEdgeInsets = .zero {
			didSet { if deviceSafeArea != oldValue { applySafeArea() } }
		}

		override func viewSafeAreaInsetsDidChange() {
			super.viewSafeAreaInsetsDidChange()
			applySafeArea()
		}

		private func applySafeArea() {
			let total = view.safeAreaInsets, added = additionalSafeAreaInsets
			let inherited = UIEdgeInsets(top: total.top - added.top, left: total.left - added.left, bottom: total.bottom - added.bottom, right: total.right - added.right)
			let needed = UIEdgeInsets(top: max(0, deviceSafeArea.top - inherited.top), left: max(0, deviceSafeArea.left - inherited.left), bottom: max(0, deviceSafeArea.bottom - inherited.bottom), right: max(0, deviceSafeArea.right - inherited.right))
			if needed != added { additionalSafeAreaInsets = needed }
		}
	}
#endif
