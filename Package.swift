// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CheSvgMCP",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CheSvgMCPCore", targets: ["CheSvgMCPCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.2")
    ],
    targets: [
        .target(
            name: "CheSvgMCPCore",
            dependencies: [.product(name: "MCP", package: "swift-sdk")],
            path: "Sources/CheSvgMCPCore"
        ),
        .executableTarget(
            name: "CheSvgMCP",
            dependencies: ["CheSvgMCPCore"],
            path: "Sources/CheSvgMCP"
        ),
        .testTarget(
            name: "CheSvgMCPTests",
            dependencies: ["CheSvgMCPCore"],
            path: "Tests/CheSvgMCPTests"
        )
    ]
)
