//
//  AppDelegate.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainCoordinator: MainCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let rootNavController = RootNavigationController()
        self.initializeKeyWindow(with: rootNavController)
        self.initializeMainCoordinator(with: rootNavController, withOptions: launchOptions)
        UserDefaults.standard.set(nil, forKey: Routine.currentRoutineKey)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        guard !ChannelManager.shared.isConnected else { return }

        switch LaunchManager.shared.status.value {
        case .success(_):
            if let identity = User.current()?.objectId {
                LaunchManager.shared.getChatToken(with: identity, buo: nil)
            }
        case .needsOnboarding, .isLaunching, .failed(_), .deeplink(_):
            break
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserNotificationManager.shared.registerPush(from: deviceToken)
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return LaunchManager.shared.continueUser(activity: userActivity)
    }
}

