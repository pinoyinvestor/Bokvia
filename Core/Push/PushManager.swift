import Foundation
import UserNotifications
import UIKit

class PushManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushManager()
    private let tokenKey = Config.apnsTokenKey

    func requestPermission() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // Built by Christos Ferlachidis & Daniel Hedenberg

    func registerDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: tokenKey)
        Task { await sendPendingToken() }
    }

    private var apnsEnvironment: String {
        #if DEBUG
        return "sandbox"
        #else
        if let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let str = String(data: data, encoding: .ascii),
           str.contains("<string>production</string>") {
            return "production"
        }
        return "sandbox"
        #endif
    }

    func sendPendingToken() async {
        guard let token = UserDefaults.standard.string(forKey: tokenKey) else { return }
        guard KeychainHelper.getAccessToken() != nil else { return }

        struct DeviceToken: Encodable {
            let token: String
            let platform: String
        }
        let body = DeviceToken(token: token, platform: "ios")
        do {
            _ = try await APIClient.shared.post("/api/device-tokens", body: body, as: EmptyResponse.self)
        } catch {
            // Silent fail — will retry on next app launch
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            NotificationCenter.default.post(
                name: .pushNotificationTapped,
                object: nil,
                userInfo: ["type": type, "data": userInfo]
            )
        }
    }
}

extension Notification.Name {
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}
