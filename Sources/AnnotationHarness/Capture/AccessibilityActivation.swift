#if DEBUG && os(iOS)
	import Foundation

	/// Turns on the app's accessibility runtime, as an assistive technology would.
	///
	/// SwiftUI builds its accessibility tree only once something asks for it (VoiceOver, UI tests,
	/// Accessibility Inspector); until then hosting views expose no elements and a capture's tree is empty.
	/// This is the same switch snapshot-testing tools use (`_AXSApplicationAccessibilitySetEnabled` in
	/// libAccessibility). It's private API, which is acceptable only because this file is DEBUG-only.
	@MainActor enum AccessibilityActivation {
		private static var isActive = false

		static func activate() {
			guard !isActive, let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW), let symbol = dlsym(library, "_AXSApplicationAccessibilitySetEnabled") else { return }
			typealias SetEnabled = @convention(c) (Bool) -> Void
			unsafeBitCast(symbol, to: SetEnabled.self)(true)
			isActive = true
		}
	}
#endif
