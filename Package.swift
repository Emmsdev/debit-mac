// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DebitMac",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "DebitMac", targets: ["DebitMac"])],
    targets: [
        .target(name: "TrafficCore"),
        .executableTarget(name: "DebitMac", dependencies: ["TrafficCore"]),
        .testTarget(name: "TrafficCoreTests", dependencies: ["TrafficCore"]),
    ]
)
