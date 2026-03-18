// swift-tools-version: 5.9
// This file documents SPM dependencies — add these via Xcode's Package Manager UI
// File → Add Package Dependencies...

import PackageDescription

let package = Package(
    name: "TimeControl",
    platforms: [.iOS(.v16)],
    dependencies: [
        // Firebase iOS SDK
        // URL: https://github.com/firebase/firebase-ios-sdk
        // Products to add: FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "10.0.0"
        ),
        // Google Sign-In
        // URL: https://github.com/google/GoogleSignIn-iOS
        // Products to add: GoogleSignIn, GoogleSignInSwift
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            from: "7.0.0"
        ),
    ],
    targets: [
        .target(
            name: "TimeControl",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ]
        ),
    ]
)
