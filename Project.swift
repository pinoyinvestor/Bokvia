// Xcode Project Configuration for Bokvia iOS App
// This file documents the project setup — create the actual .xcodeproj in Xcode on Mac
//
// Bundle ID: se.bokvia.app
// Deployment Target: iOS 17.0
// Swift Language Version: 5.10+
// Built by Christos Ferlachidis & Daniel Hedenberg
//
// SPM Dependencies:
//   - Kingfisher (https://github.com/onevcat/Kingfisher) — image caching
//   - GoogleSignIn-iOS (https://github.com/google/GoogleSignIn-iOS) — Google OAuth
//   - Note: No Stripe needed — customers pay at the salon
//   - firebase-ios-sdk (https://github.com/firebase/firebase-ios-sdk) — push + analytics
//
// Capabilities:
//   - Push Notifications
//   - Sign in with Apple
//   - Associated Domains (for universal links)
//
// Build Phases:
//   1. Compile Swift sources (all .swift files)
//   2. Copy Resources (PrivacyInfo.xcprivacy, Assets.xcassets)
