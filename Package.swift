// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CodexPetHUD",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "PetHUDCore", targets: ["PetHUDCore"]),
        .executable(name: "CodexPetHUD", targets: ["CodexPetHUD"]),
    ],
    targets: [
        .target(name: "PetHUDCore"),
        .executableTarget(
            name: "CodexPetHUD",
            dependencies: ["PetHUDCore"]
        ),
        .testTarget(name: "PetHUDCoreTests", dependencies: ["PetHUDCore"]),
    ]
)
