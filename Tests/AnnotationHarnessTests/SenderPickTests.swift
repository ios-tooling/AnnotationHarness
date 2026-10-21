#if DEBUG
	import Foundation
	import Testing
	@testable import AnnotationCore
	@testable import AnnotationHarness

	@MainActor struct SenderPickTests {
		let library = UUID()
		let inspector = UUID()

		@Test("The picker stays in the window that claimed it after that window stops appearing active")
		func staysInClaimingWindow() {
			let sender = Self.sender()
			sender.claimPick(for: inspector, isActive: false)
			sender.claimPick(for: library, isActive: true)
			// On a Mac, the picker takes key from the window as it's presented.
			sender.claimPick(for: library, isActive: false)
			#expect(sender.showsPick(in: library))
			#expect(!sender.showsPick(in: inspector))
		}

		@Test("Another active window can't take a pick that's already claimed, nor dismiss it")
		func firstClaimWins() {
			let sender = Self.sender()
			sender.claimPick(for: library, isActive: true)
			sender.claimPick(for: inspector, isActive: true)
			sender.dismissPick(in: inspector)
			#expect(sender.showsPick(in: library))
			#expect(!sender.showsPick(in: inspector))
		}

		@Test("Cancel clears the pick, so the next one shows again")
		func cancelClears() {
			let sender = Self.sender()
			sender.claimPick(for: library, isActive: true)
			sender.dismissPick(in: library)
			#expect(sender.pick == nil)
			sender.pick = Self.pick()
			sender.claimPick(for: library, isActive: true)
			#expect(sender.showsPick(in: library))
		}

		@Test("A pick that arrived while no window was active is claimed by the next window to become active")
		func unclaimedPick() {
			let sender = Self.sender()
			sender.claimPick(for: library, isActive: false)
			#expect(!sender.showsPick(in: library))
			sender.claimPick(for: inspector, isActive: true)
			#expect(sender.showsPick(in: inspector))
		}

		@Test("Choosing a companion clears the pick and remembers the choice")
		func choosing() throws {
			let sender = Self.sender()
			sender.claimPick(for: library, isActive: true)
			let pick = try #require(sender.pick)
			sender.send(pick.envelope, to: pick.companions[1])
			#expect(sender.pick == nil)
			#expect(sender.remembered == "M3 Studio (2)")
			#expect(SendTarget.choose(found: pick.companions.map(\.name), remembered: sender.remembered, sameDeviceAvailable: false) == .companion("M3 Studio (2)"))
		}

		@Test("Companions whose names Bonjour suffixed to keep them apart are told apart")
		func suffixedNames() {
			let found = ["M3 Studio", "M3 Studio (2)"]
			#expect(SendTarget.choose(found: found, remembered: nil, sameDeviceAvailable: false) == .ask(found))
			#expect(SendTarget.choose(found: found, remembered: "M3 Studio", sameDeviceAvailable: false) == .companion("M3 Studio"))
			#expect(SendTarget.choose(found: found, remembered: "M3 Studio (2)", sameDeviceAvailable: false) == .companion("M3 Studio (2)"))
		}

		/// A sender with a pick pending between two companions.
		private static func sender() -> AnnotationSender {
			let sender = AnnotationSender()
			sender.pick = pick()
			return sender
		}

		/// Port 9 (discard) on loopback, so a send to it fails at once rather than reaching anything.
		private static func pick() -> AnnotationSender.Pick {
			let companions = ["M3 Studio", "M3 Studio (2)"].map { CompanionBrowser.Companion(name: $0, endpoint: .hostPort(host: "127.0.0.1", port: 9)) }
			return AnnotationSender.Pick(envelope: .sample, companions: companions)
		}
	}
#endif
