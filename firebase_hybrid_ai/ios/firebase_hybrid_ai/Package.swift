// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "firebase_hybrid_ai",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "firebase-hybrid-ai", targets: ["firebase_hybrid_ai"])
    ],
    dependencies: [
        // Firebase AI Logic provides the Gemini model for Apple's Foundation Models framework. The range starts at the
        // version this plugin was written against and ends before the next major version. The app's other Firebase
        // plugins, such as firebase_core, pin an exact version inside it.
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "13.1.0"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "firebase_hybrid_ai",
            dependencies: [
                .product(name: "FirebaseAILogic", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
