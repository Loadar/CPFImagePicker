// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "CPFImagePicker",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "CPFImagePicker",
            targets: ["CPFImagePicker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/devxoul/Then", from: Version("3.0.0")),
        .package(url: "https://github.com/Loadar/CPFUIKit.git", from: Version("0.2.3")),
    ],
    targets: [
        .target(
            name: "CPFImagePicker",
            dependencies: ["Then", "CPFUIKit"],
            resources: [
                .process("Resources/back.png"),
                .process("Resources/popUp.png"),
                .process("Resources/unselected.png"),
                .process("Resources/selected.png"),
                .process("Resources/selectedBackground.png"),
                .process("Resources/add.png"),
                .process("Resources/camera.png"),
                .copy("../PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "CPFImagePickerTests",
            dependencies: ["CPFImagePicker"]
        ),
    ]
)
