//
//  AppDelegate.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainCoordinator: MainCoordinator?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

#if !NOTIFICATION
        let rootNavController = RootNavigationController()
        self.initializeKeyWindow(with: rootNavController)
        self.initializeMainCoordinator(with: rootNavController, withOptions: launchOptions)
        _ = UserNotificationManager.shared
#endif

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        self.prepareCurrentUser()
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return LaunchManager.shared.continueUser(activity: userActivity)
    }

#if !APPCLIP
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await UserNotificationManager.shared.registerPush(from: deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("DID FAIL TO REGISTER FOR PUSH \(error)")
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        print("DID RECEIVE REMOTE NOTIFICATION")
        guard application.applicationState == .active || application.applicationState == .inactive else {
            completionHandler(.noData)
            return
        }

        if UserNotificationManager.shared.handle(userInfo: userInfo) {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
#endif

    private func prepareCurrentUser() {
#if !NOTIFICATION
        UserNotificationManager.shared.resetBadgeCount()
#endif
    }
}

