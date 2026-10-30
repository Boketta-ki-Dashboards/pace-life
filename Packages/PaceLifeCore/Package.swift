// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PaceLifeCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PaceLifeCore", targets: ["PaceLifeCore"])],
    targets: [
        .target(name: "PaceLifeCore"),
        .testTarget(name: "PaceLifeCoreTests", dependencies: ["PaceLifeCore"])
    ]
)
