// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CPFImagePicker",
    platforms: [.iOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CPFImagePicker",
            targets: ["CPFImagePicker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/devxoul/Then", from: Version("3.0.0")),
        .package(url: "https://github.com/Loadar/CPFUIKit.git", from: Version("0.2.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CPFImagePicker",
            dependencies: ["Then", "CPFUIKit"],
            resources: [
                .process("Resources/back.png"),
                .process("Resources/popUp.png"),
                .process("Resources/unselected.png"),
                .process("Resources/selected.png"),
                .process("Resources/add.png"),
            ]
        ),
        .testTarget(
            name: "CPFImagePickerTests",
            dependencies: ["CPFImagePicker"]),
    ]
)
