import UIKit
import os

class AppDelegate: NSObject, UIApplicationDelegate {
    private let bgLogger = Logger(subsystem: Config.bundleId, category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: Config.actionExplore,
                localizedTitle: "Utforska",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass"),
                userInfo: nil
            ),
            // Built by Christos Ferlachidis & Daniel Hedenberg
            UIApplicationShortcutItem(
                type: Config.actionBookings,
                localizedTitle: "Mina bokningar",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "calendar"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: Config.actionChat,
                localizedTitle: "Chatt",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "bubble.left.and.bubble.right.fill"),
                userInfo: nil
            )
        ]
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionManager.shared.pendingAction = shortcutItem.type
        }
        return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushManager.shared.registerDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        bgLogger.error("Failed to register for push: \(error.localizedDescription)")
    }
}
