#if DEBUG
	import Foundation
	import Testing
	@testable import AnnotationCore
	@testable import AnnotationHarness
	#if os(macOS)
		import AppKit
		import SwiftUI
	#endif

	struct SendTargetTests {
		@Test("With nothing on the network, the same-device path is used when it's there")
		func nothingFound() {
			#expect(SendTarget.choose(found: [], remembered: nil, sameDeviceAvailable: true) == .sameDevice)
			#expect(SendTarget.choose(found: [], remembered: "Desk iPad", sameDeviceAvailable: false) == .nothingFound)
		}

		@Test("A single companion is used without asking, even over a different earlier choice")
		func single() {
			#expect(SendTarget.choose(found: ["Desk iPad"], remembered: nil, sameDeviceAvailable: true) == .companion("Desk iPad"))
			#expect(SendTarget.choose(found: ["Desk iPad"], remembered: "Sofa iPad", sameDeviceAvailable: false) == .companion("Desk iPad"))
		}

		@Test("With several, the earlier choice wins while it's still there; otherwise the user is asked")
		func several() {
			let found = ["Desk iPad", "Sofa iPad"]
			#expect(SendTarget.choose(found: found, remembered: "Sofa iPad", sameDeviceAvailable: false) == .companion("Sofa iPad"))
			#expect(SendTarget.choose(found: found, remembered: "Gone iPad", sameDeviceAvailable: true) == .ask(found))
			#expect(SendTarget.choose(found: found, remembered: nil, sameDeviceAvailable: false) == .ask(found))
		}
	}

	#if os(macOS)
		@MainActor struct MacSenderTests {
			@Test("A Mac window's capture reaches a companion on this machine", .timeLimit(.minutes(1)))
			func sendsWindow() async throws {
				let (window, button) = Self.window()
				defer { window.close() }
				// A whole second, since the header's ISO 8601 dates drop fractions.
				let envelope = try #require(WindowCapture.envelope(of: window, screenName: "Inbox", date: Date(timeIntervalSince1970: 1_790_000_000)))
				#expect(envelope.layout == .macWindow(size: window.frame.size))
				#expect(envelope.imageScale > 0)
				let reply = try #require(envelope.accessibility.first { $0.label == "Reply" })
				#expect(reply.traits.first == "button")
				// The button's frame in the window (origin bottom-left), measured from the top-left instead.
				// AppKit's accessibility frame takes in the bezel, so it can be a point or two larger than the view.
				let inWindow = button.convert(button.bounds, to: nil)
				#expect(abs(reply.frame.minX - inWindow.minX) <= 2)
				#expect(abs(reply.frame.minY - (window.frame.height - inWindow.maxY)) <= 2)

				let listener = CompanionListener(name: "AnnotationHarnessTests-\(UUID().uuidString.prefix(8))")
				do {
					try await listener.start()
				} catch {
					try Test.cancel("Skipped: networking isn't available in this test environment (\(error))")
				}
				defer { listener.stop() }
				let port = try #require(listener.port)

				let sender = AnnotationSender()
				await sender.deliver(envelope, to: CompanionBrowser.Companion(name: "Loopback", endpoint: .hostPort(host: "127.0.0.1", port: port)))
				#expect(sender.status == "Sent to Loopback")
				var received = listener.envelopes.makeAsyncIterator()
				let arrived = try #require(await received.next())
				#expect(arrived == envelope)
				#expect(arrived.screenName == "Inbox")
				#expect(!arrived.png.isEmpty)
			}

			@Test("A SwiftUI window's capture lists its buttons, text and text fields, but not the window's own buttons")
			func listsSwiftUIElements() throws {
				let window = Self.window(frame: CGRect(x: 460, y: 140, width: 360, height: 240), styleMask: [.titled, .closable, .miniaturizable, .resizable])
				defer { window.close() }
				window.contentView = NSHostingView(rootView: SwiftUISample())
				// Labelled, so they'd be listed if they weren't left out as the window's own.
				let windowButtons = [NSWindow.ButtonType.closeButton: "Close", .miniaturizeButton: "Minimize", .zoomButton: "Zoom"]
				for (type, label) in windowButtons { window.standardWindowButton(type)?.setAccessibilityLabel(label) }
				let nodes = try #require(WindowCapture.envelope(of: window, screenName: "Library")).accessibility
				let add = try #require(nodes.first { $0.label == "Add Book" })
				#expect(add.traits.first == "button")
				// AppKit reads static text as its value.
				let title = try #require(nodes.first { $0.value == "The Hobbit" })
				#expect(title.traits.first == "text")
				let search = try #require(nodes.first { $0.label == "Search books" })
				#expect(search.traits.first == "textField")
				#expect(!nodes.contains { windowButtons.values.contains($0.label ?? "") }, "\(nodes.map(\.line))")
			}
		}
	#endif
#endif
