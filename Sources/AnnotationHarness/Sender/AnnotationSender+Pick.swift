#if DEBUG
	import Foundation

	/// Which window shows the companion picker. Every window with `.annotationSender()` shares the one sender, so the first
	/// active window to see a pick claims it, and the picker stays in that window from then on. It can't follow the window's
	/// active state: on a Mac, presenting the picker takes key from the window, and the picker would be dismissed at once.
	extension AnnotationSender {
		/// Claims the pending pick for `window`, if it's active and no window has claimed it yet.
		func claimPick(for window: UUID, isActive: Bool) {
			guard isActive, pick != nil, pick?.window == nil else { return }
			pick?.window = window
		}

		/// Whether `window` shows the picker.
		func showsPick(in window: UUID) -> Bool {
			pick != nil && pick?.window == window
		}

		/// The picker in `window` was dismissed, by Cancel or a pick: drops the pending pick so the next send starts over.
		func dismissPick(in window: UUID) {
			if showsPick(in: window) { pick = nil }
		}
	}
#endif
