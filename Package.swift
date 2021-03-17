// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ArArchiveKit",
    products: [
        .library(
            name: "ArArchiveKit",
            targets: ["ArArchiveKit"]
		),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ArArchiveKit",
            dependencies: []
		),
        .testTarget(
            name: "ArArchiveKitTests",
			dependencies: ["ArArchiveKit"],
			resources: [
				.copy("test-files/"),
			]
		),
    ]
)
