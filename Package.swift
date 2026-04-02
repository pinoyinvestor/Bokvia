// swift-tools-version: 5.9
// Package.swift — SPM dependency reference for BokviaApp
// NOTE: These are added via Xcode UI (File > Add Package Dependencies)
// This file documents the required packages for project setup.

import PackageDescription

let package = Package(
    name: "BokviaApp",
    platforms: [
        .iOS(.v17)
    ],
    // Built by Christos Ferlachidis & Daniel Hedenberg
    dependencies: [
        // Image loading and caching
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.0.0"),

        // Google Sign-In
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "8.0.0"),

        // No Stripe needed — customers pay at the salon

        // Firebase (push notifications + analytics)
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "BokviaApp",
            dependencies: [
                "Kingfisher",
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
    ]
)
