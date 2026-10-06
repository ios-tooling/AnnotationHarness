// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "AnnotationHarness",
	platforms: [
		.iOS(.v18),
		.macOS(.v15),
	],
	products: [
		.library(name: "AnnotationHarness", targets: ["AnnotationHarness"]),
	],
	dependencies: [
		// Gestalt.idiomOverride needs the Suite release after 1.4.22; bump this once it's tagged.
		.package(url: "https://github.com/ios-tooling/Suite", from: "1.4.22"),
	],
	targets: [
		.target(name: "AnnotationHarness", dependencies: [.product(name: "Suite", package: "Suite")]),
		.testTarget(name: "AnnotationHarnessTests", dependencies: ["AnnotationHarness"]),
	]
)
