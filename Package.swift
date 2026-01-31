// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Telme",
	products: [
		.library(
			name: "Telme",
			targets: ["Telme"]
		)
	],
	dependencies: [
		.package(
			url: "https://github.com/vsmbd/swift-core.git",
			branch: "main"
		),
		.package(
			url: "https://github.com/vsmbd/swift-eventdispatch.git",
			branch: "main"
		)
	],
	targets: [
		.target(
			name: "Telme",
			dependencies: [
				.product(
					name: "SwiftCore",
					package: "swift-core"
				),
				.product(
					name: "EventDispatch",
					package: "swift-eventdispatch"
				)
			],
			path: "Sources/Telme"
		),
		.testTarget(
			name: "TelmeTests",
			dependencies: ["Telme"],
			path: "Tests/TelmeTests"
		)
	]
)
