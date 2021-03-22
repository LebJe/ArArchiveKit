// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Foundationless",
    dependencies: [.package(path: "../../")],
    targets: [
        .target(
            name: "Foundationless",
            dependencies: [
				.product(name: "ArArchiveKit", package: "ArArchiveKit")
			]
		),
        .testTarget(
            name: "FoundationlessTests",
            dependencies: ["Foundationless"]
		),
    ]
)
