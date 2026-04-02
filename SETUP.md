# Bokvia iOS App — Setup Guide

## Prerequisites

- macOS with Xcode 15+ installed
- Apple Developer account (for push notifications and Sign in with Apple)
- Firebase project with iOS app configured
- Google Cloud project with OAuth 2.0 client ID

## Steps

### 1. Clone the Repository

```bash
cd ~/Apps
git clone git@github.com:christaras9126/bokvia-ios.git BokviaApp
```

### 2. Create Xcode Project

Open Xcode and create a new project:

- **Template:** iOS > App
- **Product Name:** BokviaApp
- **Bundle Identifier:** se.bokvia.app
- **Language:** Swift
- **Interface:** SwiftUI
- **Deployment Target:** iOS 17.0

<!-- Built by Christos Ferlachidis & Daniel Hedenberg -->

### 3. Add Source Files

Drag these folders into the Xcode project navigator:

- `App/` — App entry point and root views
- `Core/` — Networking, auth, extensions, utilities
- `Features/` — Feature modules (booking, profile, salon, etc.)
- `Models/` — Data models and DTOs
- `Resources/` — Assets, colors, fonts
- `Shared/` — Shared UI components

### 4. Add SPM Dependencies

Go to **File > Add Package Dependencies** and add each:

| Package | URL | Version |
|---------|-----|---------|
| Kingfisher | `https://github.com/onevcat/Kingfisher` | 8.0.0+ |
| GoogleSignIn-iOS | `https://github.com/google/GoogleSignIn-iOS` | 8.0.0+ |
| stripe-ios | `https://github.com/stripe/stripe-ios` | 24.0.0+ |
| firebase-ios-sdk | `https://github.com/firebase/firebase-ios-sdk` | 11.0.0+ |

For Firebase, select these products: **FirebaseMessaging**, **FirebaseAnalytics**

### 5. Configure Entitlements

1. Select the BokviaApp target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add:
   - Push Notifications
   - Sign in with Apple
4. Verify `BokviaApp.entitlements` is set in Build Settings > Code Signing Entitlements

### 6. Add Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Download `GoogleService-Info.plist` for the iOS app
3. Drag it into the Xcode project root (check "Copy items if needed")

### 7. Configure Google Sign-In URL Scheme

1. Open `GoogleService-Info.plist` and copy the `REVERSED_CLIENT_ID` value
2. In Xcode, go to target > **Info** > **URL Types**
3. Add a new URL scheme with the reversed client ID

### 8. Update Info.plist

Make sure `Info.plist` contains:

- `NSLocationWhenInUseUsageDescription` — for salon map
- `NSCameraUsageDescription` — for profile photo
- `NSPhotoLibraryUsageDescription` — for profile photo
- URL schemes for Google Sign-In

### 9. Build and Run

1. Select a simulator (iPhone 15 Pro recommended) or your device
2. Press **Cmd+R** to build and run
3. Verify the app launches and shows the login/onboarding screen

## Troubleshooting

- **Firebase not found:** Make sure `GoogleService-Info.plist` is in the target's build phase "Copy Bundle Resources"
- **Signing errors:** Ensure your Apple Developer team is selected in Signing & Capabilities
- **Google Sign-In fails:** Double-check the URL scheme matches `REVERSED_CLIENT_ID`
