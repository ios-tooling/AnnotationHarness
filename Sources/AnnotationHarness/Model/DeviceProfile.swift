#if DEBUG
	import SwiftUI

	/// An iPhone screen the harness can imitate: its size and safe area in points.
	struct DeviceProfile: Identifiable, Equatable, Sendable {
		let id: String
		let name: String
		let size: CGSize
		let safeArea: EdgeInsets
		let cornerRadius: CGFloat
		let cutout: Cutout

		/// What sits at the top of the screen, which the fake status bar draws around.
		enum Cutout: Equatable, Sendable {
			case island(CGSize, top: CGFloat)
			case notch(CGSize)
			case none
		}

		static let all: [DeviceProfile] = [
			DeviceProfile(id: "iphone-17-pro", name: "iPhone 17 Pro", size: CGSize(width: 402, height: 874), safeArea: EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0), cornerRadius: 55, cutout: .island(CGSize(width: 125, height: 37), top: 11)),
			DeviceProfile(id: "iphone-17-pro-max", name: "iPhone 17 Pro Max", size: CGSize(width: 440, height: 956), safeArea: EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0), cornerRadius: 55, cutout: .island(CGSize(width: 125, height: 37), top: 11)),
			DeviceProfile(id: "iphone-air", name: "iPhone Air", size: CGSize(width: 420, height: 912), safeArea: EdgeInsets(top: 68, leading: 0, bottom: 34, trailing: 0), cornerRadius: 62, cutout: .island(CGSize(width: 125, height: 37), top: 14)),
			DeviceProfile(id: "iphone-16e", name: "iPhone 16e", size: CGSize(width: 390, height: 844), safeArea: EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0), cornerRadius: 47, cutout: .notch(CGSize(width: 162, height: 33))),
			DeviceProfile(id: "iphone-se", name: "iPhone SE", size: CGSize(width: 375, height: 667), safeArea: EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0), cornerRadius: 0, cutout: .none),
		]

		static let standard = all[0]

		static func named(_ id: String?) -> DeviceProfile {
			all.first { $0.id == id } ?? standard
		}

		/// The scale that fits the screen into `available`; never above 1, so it shows at real size whenever it fits.
		func fitScale(in available: CGSize) -> CGFloat {
			guard available.width > 0, available.height > 0 else { return 1 }
			return min(1, available.width / size.width, available.height / size.height)
		}
	}
#endif
