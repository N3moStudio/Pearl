// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PearlCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [.library(name: "PearlCore", targets: ["PearlCore"])],
    targets: [.target(name: "PearlCore"), .testTarget(name: "PearlCoreTests", dependencies: ["PearlCore"])]
)
