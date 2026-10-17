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
		// Linked only by the companion app in Apps/Companion.
		.library(name: "AnnotationCompanion", targets: ["AnnotationCompanion"]),
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
		// The companion app's feature code: inbox, sessions per source app and its screens; the app target only hosts it.
		.target(name: "AnnotationCompanion", dependencies: ["AnnotationCore", "AnnotationUI"]),
		.testTarget(name: "AnnotationHarnessTests", dependencies: ["AnnotationCore", "AnnotationHarness"]),
		.testTarget(name: "AnnotationCompanionTests", dependencies: ["AnnotationCore", "AnnotationCompanion"]),
	]
)
