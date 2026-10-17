#if DEBUG
	/// Where a send goes, decided from the companions found on the network.
	enum SendTarget: Equatable {
		/// The companion advertising under this name.
		case companion(String)
		/// Several companions and no earlier choice among them: ask which, from these names.
		case ask([String])
		/// Nothing on the network, but a companion is installed on this device.
		case sameDevice
		/// Nowhere to send.
		case nothingFound

		/// One companion is used as is. With several, the one chosen earlier in this run wins while it's still there.
		static func choose(found: [String], remembered: String?, sameDeviceAvailable: Bool) -> SendTarget {
			switch found.count {
			case 0:
				sameDeviceAvailable ? .sameDevice : .nothingFound
			case 1:
				.companion(found[0])
			default:
				if let remembered, found.contains(remembered) { .companion(remembered) } else { .ask(found) }
			}
		}
	}
#endif
