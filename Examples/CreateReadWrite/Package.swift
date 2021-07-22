// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "CreateReadWrite",
	platforms: [.macOS(.v10_15)],
	products: [
		.executable(name: "create", targets: ["CreateArchive"]),
		.executable(name: "read", targets: ["ReadArchive"]),
		.executable(name: "extract", targets: ["ExtractArchive"]),
	],
	dependencies: [.package(name: "ArArchiveKit", path: "../../")],
	targets: [
		// .target(
		// 	name: "Utilities",
		// 	dependencies: [
		// 		.product(name: "CPIOArchiveKit", package: "CPIOArchiveKit"),
		// 	]
		// ),
		.target(
			name: "CreateArchive",
			dependencies: [
				.product(name: "ArArchiveKit", package: "ArArchiveKit"),
			]
		),
		.target(
			name: "ReadArchive",
			dependencies: [
				.product(name: "ArArchiveKit", package: "ArArchiveKit"),
			]
		),
		.target(
			name: "ExtractArchive",
			dependencies: [
				.product(name: "ArArchiveKit", package: "ArArchiveKit"),
			]
		),
	]
)
