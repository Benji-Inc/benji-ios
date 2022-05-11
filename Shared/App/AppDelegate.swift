//
//  AppDelegate.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    #if !APPCLIP
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await UserNotificationManager.shared.registerPush(from: deviceToken)
        }
    }
    
    func applicationSignificantTimeChange(_ application: UIApplication) {
        if let user = User.current(), user.isAuthenticated {
            // Update the timeZone
            user.timeZone = TimeZone.current.identifier
            user.saveEventually()
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        print("DID FAIL TO REGISTER FOR PUSH \(error)")
    }
    #endif
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var mainCoordinator: MainCoordinator?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
#if !NOTIFICATION
        let rootNavController = RootNavigationController()
        self.initializeKeyWindow(with: rootNavController, for: windowScene)
        self.initializeMainCoordinator(with: rootNavController)
        _ = UserNotificationManager.shared
#endif
        // Must be done after maincoordinator is initialized so delegate get set
        if let activity = connectionOptions.userActivities.first(where: { activity in
            return activity.activityType == NSUserActivityTypeBrowsingWeb
        }) {
            LaunchManager.shared.continueUser(activity: activity)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        LaunchManager.shared.continueUser(activity: userActivity)
    }
        
    func initializeKeyWindow(with rootViewController: UIViewController, for scene: UIWindowScene) {
        self.window = UIWindow(windowScene: scene)
        self.window?.rootViewController = rootViewController
        self.window?.makeKeyAndVisible()
    }

    func initializeMainCoordinator(with rootNavController: RootNavigationController) {
        let router = Router(navController: rootNavController)
        self.mainCoordinator = MainCoordinator(router: router, deepLink: nil)
        self.mainCoordinator?.start()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
        UserDefaults(suiteName: Config.shared.environment.groupId)?.set(badgeNumber, forKey: "badgeNumber")
    }
}
