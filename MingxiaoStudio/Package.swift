// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MingxiaoStudio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MingxiaoStudio", targets: ["MingxiaoStudio"])
    ],
    targets: [
        .executableTarget(
            name: "MingxiaoStudio",
            path: "Sources/MingxiaoStudio",
            resources: [.copy("Resources")]
        )
    ]
)
