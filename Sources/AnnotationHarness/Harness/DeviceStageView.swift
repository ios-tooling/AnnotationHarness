#if DEBUG && os(iOS)
	import SwiftUI

	/// Reserves room for the device on the stage and places the phone window over it,
	/// at real size whenever it fits and scaled down only when it doesn't.
	struct DeviceStageView<Content: View>: View {
		let device: DeviceProfile
		let content: Content
		let stage: StageGeometry
		let hidesPhone: Bool
		@State private var frame: CGRect = .zero

		var body: some View {
			GeometryReader { proxy in
				let scale = device.fitScale(in: proxy.size)
				PhoneHost(content: content, device: device, frame: frame, scale: scale, isHidden: hidesPhone, stage: stage)
					.frame(width: device.size.width * scale, height: device.size.height * scale)
					.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			.padding()
			.background(.background.secondary)
		}
	}
#endif
