#if DEBUG && os(iOS)
	import SwiftUI

	/// A stand-in iPhone status bar drawn over the top of the phone window: the time on the left,
	/// signal, Wi-Fi and battery on the right, around the device's Dynamic Island or notch.
	/// Decoration only, so it takes no touches and stays out of the accessibility tree.
	struct FakeStatusBarView: View {
		let device: DeviceProfile

		var body: some View {
			HStack(spacing: 0) {
				TimelineView(.everyMinute) { context in
					Text(context.date, format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
						.monospacedDigit()
				}
				.frame(maxWidth: .infinity)
				CutoutView(cutout: device.cutout)
				HStack(spacing: 4) {
					Image(systemName: "cellularbars")
					Image(systemName: "wifi")
					Image(systemName: "battery.100percent")
				}
				.frame(maxWidth: .infinity)
			}
			.font(.subheadline.weight(.semibold))
			.frame(height: bandHeight)
			.padding(.top, bandTop)
			.frame(maxHeight: .infinity, alignment: .top)
			.allowsHitTesting(false)
			.accessibilityHidden(true)
		}

		/// The status bar's items are centred vertically on the cutout, or on the whole bar without one.
		private var bandTop: CGFloat {
			if case .island(_, let top) = device.cutout { return top }
			return 0
		}

		private var bandHeight: CGFloat {
			switch device.cutout {
			case .island(let size, _), .notch(let size): size.height
			case .none: device.safeArea.top
			}
		}
	}

	struct CutoutView: View {
		let cutout: DeviceProfile.Cutout

		var body: some View {
			switch cutout {
			case .island(let size, _):
				Capsule().fill(.black).frame(width: size.width, height: size.height)
			case .notch(let size):
				UnevenRoundedRectangle(bottomLeadingRadius: size.height / 2, bottomTrailingRadius: size.height / 2)
					.fill(.black)
					.frame(width: size.width, height: size.height)
			case .none:
				EmptyView()
			}
		}
	}
#endif
