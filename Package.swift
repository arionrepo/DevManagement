// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DevManagement",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "dev-manager-cli", targets: ["DevManagementCLI"]),
        .executable(name: "dev-manager", targets: ["DevManagementGUI"])
    ],
    dependencies: [
    ],
    targets: [
        // Shared core module for CLI and GUI
        .target(
            name: "DevManagementCore",
            dependencies: [],
            path: "Sources/Core"
        ),

        // CLI target (existing functionality)
        .executableTarget(
            name: "DevManagementCLI",
            dependencies: ["DevManagementCore"],
            path: "Sources/CLI"
        ),

        // GUI target (new MenuBarExtra application)
        .executableTarget(
            name: "DevManagementGUI",
            dependencies: ["DevManagementCore"],
            path: "Sources/GUI"
        ),

        // Tests
        .testTarget(
            name: "DevManagementTests",
            dependencies: ["DevManagementCore"],
            path: "Tests"
        )
    ]
)
