#if DEBUG
	import Testing
	@testable import AnnotationHarness

	struct LaunchArgumentTests {
		@Test("Only the launch argument turns the harness on")
		func launchArgument() {
			#expect(AnnotationHarness.isRequested(arguments: ["App", "-AnnotationHarness"]))
			#expect(!AnnotationHarness.isRequested(arguments: ["App"]))
		}
	}
#endif
