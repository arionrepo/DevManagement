// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DevManagement",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "dev-manager", targets: ["DevManagement"])
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "DevManagement",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DevManagementTests",
            dependencies: ["DevManagement"],
            path: "Tests"
        )
    ]
)
