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
		.package(url: "https://github.com/ios-tooling/Suite", from: "1.4.23"),
	],
	targets: [
		// Model, report, wire format and transport; not DEBUG-gated, so the companion app can ship them.
		.target(name: "AnnotationCore"),
		// The Pencil markup screen and share sheet (iOS only); not DEBUG-gated either.
		.target(name: "AnnotationUI", dependencies: ["AnnotationCore"]),
		// The in-app harness host apps link; everything in it stays inside `#if DEBUG`.
		.target(name: "AnnotationHarness", dependencies: ["AnnotationCore", "AnnotationUI", .product(name: "Suite", package: "Suite")]),
		.testTarget(name: "AnnotationHarnessTests", dependencies: ["AnnotationCore", "AnnotationHarness"]),
	]
)
