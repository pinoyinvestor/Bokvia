# Bokvia iOS

Native SwiftUI booking app for Bokvia — beauty & wellness platform.

## Version
**v1.0.0** (Beta)

## Requirements
- iOS 17.0+
- Xcode 16+
- Swift 5.10+

## Setup
1. Open project in Xcode
2. Add SPM dependencies:
   - [Kingfisher](https://github.com/onevcat/Kingfisher) — image caching
   - [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) — Google OAuth
   - [stripe-ios](https://github.com/stripe/stripe-ios) — payments
   - [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) — push notifications
3. Configure Google Sign-In: add reversed client ID to URL schemes in Info.plist
4. Enable capabilities: Push Notifications, Sign in with Apple
5. Build and run

## Features
- Email / Google / Apple Sign-In
- Explore providers (list + map)
- Booking flow (service → date → slot → confirm)
- Real-time chat with providers
- Push notifications
- Family member booking
- Provider profiles with portfolio
- Salon profiles with team view
- Saved works / favorites
- Account management with GDPR deletion
- Content moderation (report/block)
- Dark mode support
- Swedish + English

## Architecture
- **Pattern:** MVVM with @Observable
- **Auth:** OAuth 2.0 with rotating refresh tokens (cookie-based)
- **Network:** Actor-based APIClient with retry + token refresh
- **Real-time:** Socket.IO HTTP polling with reconnection
- **Storage:** Keychain for tokens, UserDefaults for preferences

## Backend
- API: https://bokvia.se (NestJS)
- Payments: Stripe (physical services — no Apple IAP required)

Built by Christos Ferlachidis & Daniel Hedenberg
