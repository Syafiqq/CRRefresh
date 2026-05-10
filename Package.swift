// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CRRefresh",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CRRefresh",
            targets: ["CRRefresh"]
        ),
    ],
    targets: [
        .target(
            name: "CRRefresh",
            path: "CRRefresh/CRRefresh",
            resources: [
                .copy("Animators/NormalAnimator/NormalHeader.bundle"),
                .copy("Animators/NormalAnimator/NormalFooter.bundle")
            ]
        ),
    ]
)
