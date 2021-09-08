//
//  AppDelegate.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import UIKit
import StreamChat

extension ChatClient {
    static var shared: ChatClient?
}

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
#endif

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.prepareCurrentUser()
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

#if !APPCLIP && !NOTIFICATION
        guard !ChatClientManager.shared.isConnected else { return }

        Task { await self.getChatToken() }
#endif
    }

#if !APPCLIP && !NOTIFICATION
    func getChatToken() async {
        do {
            let token = try await GetChatToken().makeRequest()

            if ChatClientManager.shared.client.isNil {
                try await ChatClientManager.shared.initialize(token: token)
            } else {
                try await ChatClientManager.shared.update(token: token)
            }
        } catch {
            print(error)
        }
    }
#endif
}

