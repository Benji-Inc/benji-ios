//
//  UserNotificationManager.swift
//  Benji
//
//  Created by Benji Dodgson on 9/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications
import TMROLocalization
import TwilioChatClient
import Parse
import TMROFutures

class UserNotificationManager: NSObject {

    static let shared = UserNotificationManager()

    let center = UNUserNotificationCenter.current()

    // NOTE: Retrieves the notification settings synchronously.
    // WARNING: Use with caution as it will block whatever thread it is
    // called on until a setting is retrieved.
    func getNotificationSettingsSynchronously() -> UNNotificationSettings {

        // To avoid read/write issues inherent to multithreading, create a serial dispatch queue
        // so that mutations to the notification setting var happening synchronously
        let notificationSettingsQueue = DispatchQueue(label: "notificationsQueue")

        var notificationSettings: UNNotificationSettings?

        self.center.getNotificationSettings { (settings) in
            notificationSettingsQueue.sync {
                notificationSettings = settings
            }
        }

        // Wait in a loop until we get a result back from the notification center
        while true {
            var result: UNNotificationSettings?

            // IMPORTANT: Perform reads synchrononously to ensure the value if fully written before a read.
            // If the sync is not performed, this function may never return.
            notificationSettingsQueue.sync {
                result = notificationSettings
            }

            if let strongResult = result {
                return strongResult
            }
        }
    }

    func register(with options: UNAuthorizationOptions = [.alert, .sound, .badge],
                  application: UIApplication,
                  completion: @escaping ((Bool, Error?) -> Void)) {

        self.center.requestAuthorization(options: options) { (granted, error) in
            if granted {
                runMain {
                    application.registerForRemoteNotifications()  // To update our token
                }
            } else {
                print("User Notification permission denied: \(String(describing: error?.localizedDescription))")
            }
            completion(granted, error)
        }

        self.center.delegate = self
    }

    func clearNotificationCenter() {
        let count = UIApplication.shared.applicationIconBadgeNumber
        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    func schedule(note: UNNotificationRequest) -> Future<Void> {
        let promise = Promise<Void>()
        self.center.add(note, withCompletionHandler: { (error) in
            if let e = error {
                promise.reject(with: e)
            } else {
                promise.resolve(with: ())
            }
        })

        return promise 
    }

    func registerPush(from deviceToken: Data) {
        guard let installation = PFInstallation.current() else { return }

        installation.setDeviceTokenFrom(deviceToken)
        installation.saveToken()
            .observeValue { (_) in }
    }
}
