// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dockspace",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Dockspace", targets: ["DockspaceApp"]),
        .library(name: "DockspaceCore", targets: ["DockspaceCore"]),
        .library(name: "DockspaceStorage", targets: ["DockspaceStorage"])
    ],
    targets: [
        // UI layer: SwiftUI MenuBarExtra + editor windows.
        // Depends on Core and Storage for everything else.
        .executableTarget(
            name: "DockspaceApp",
            dependencies: [
                "DockspaceCore",
                "DockspaceStorage"
            ],
            path: "Sources/DockspaceApp"
        ),

        // Pure Swift, no UI. Plist reader/writer, swapper, models.
        // Testable without any UI dependency.
        .target(
            name: "DockspaceCore",
            path: "Sources/DockspaceCore"
        ),

        // Profile persistence: JSON in Application Support.
        // Depends on Core for the model types.
        .target(
            name: "DockspaceStorage",
            dependencies: [
                "DockspaceCore"
            ],
            path: "Sources/DockspaceStorage"
        ),

        .testTarget(
            name: "DockspaceCoreTests",
            dependencies: [
                "DockspaceCore"
            ],
            path: "Tests/DockspaceCoreTests",
            resources: [
                .copy("Fixtures/sample-dock.plist")
            ]
        ),
        .testTarget(
            name: "DockspaceStorageTests",
            dependencies: [
                "DockspaceCore",
                "DockspaceStorage"
            ],
            path: "Tests/DockspaceStorageTests"
        )
    ]
)
