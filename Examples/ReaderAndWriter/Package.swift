// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "ReaderAndWriter",
	dependencies: [.package(path: "../../")],
	targets: [
		.target(
			name: "reader",
			dependencies: [
				.product(name: "ArArchiveKit", package: "ArArchiveKit"),
			]
		),
		.target(
			name: "extractor",
			dependencies: [
				.product(name: "ArArchiveKit", package: "ArArchiveKit"),
			]
		),
	]
)
