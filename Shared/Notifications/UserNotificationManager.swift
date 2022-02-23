//
//  UserNotificationManager.swift
//  Benji
//
//  Created by Benji Dodgson on 9/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications
import Parse
import Combine
#if IOS
import StreamChat
#endif

protocol UserNotificationManagerDelegate: AnyObject {
    func userNotificationManager(willHandle: DeepLinkable)
}

class UserNotificationManager: NSObject {

    static let shared = UserNotificationManager()
    weak var delegate: UserNotificationManagerDelegate?

    private let center = UNUserNotificationCenter.current()
    private(set) var application: UIApplication?

    override init() {
        super.init()

        self.center.delegate = self
    }

    func getNotificationSettings() async -> UNNotificationSettings {
        let result: UNNotificationSettings = await withCheckedContinuation { continuation in
            self.center.getNotificationSettings { (settings) in
                continuation.resume(returning:  settings)
            }
        }

        return result
    }

    func silentRegister(withApplication application: UIApplication) {
        self.application = application
        
        Task {
            let settings = await self.getNotificationSettings()

            switch settings.authorizationStatus {
            case .authorized:
                await application.registerForRemoteNotifications()  // To update our token
            case .provisional:
                await application.registerForRemoteNotifications()  // To update our token
            case .notDetermined:
                await self.register(with: [.alert, .sound, .badge, .provisional], application: application)
            case .denied, .ephemeral:
                return
            @unknown default:
                return
            }
        }
    }

    @discardableResult
    func register(with options: UNAuthorizationOptions = [.alert, .sound, .badge],
                  application: UIApplication) async -> Bool {

        self.application = application
        let granted = await self.requestAuthorization(with: options)
        if granted {
            await application.registerForRemoteNotifications()  // To update our token
        }
        return granted
    }

    private func requestAuthorization(with options: UNAuthorizationOptions = [.alert, .sound, .badge]) async -> Bool {
        do {
            let granted = try await self.center.requestAuthorization(options: options)
            if granted {
                let userCategories = UserNotificationCategory.allCases.map { userCategory in
                    return userCategory.category
                }
                let categories: Set<UNNotificationCategory> = Set.init(userCategories)
                self.center.setNotificationCategories(categories)
            }

            return granted
        } catch {
            logError(error)
            return false
        }
    }

    func registerPush(from deviceToken: Data) async {
        do {
            let installation = try await PFInstallation.getCurrent()
            installation.badge = 0
            installation.setDeviceTokenFrom(deviceToken)

            // Update the user id on the installation object if it's different than the current user's id.
            if let userId = User.current()?.objectId {
                let installationUserId = installation["userId"] as? String ?? String()

                if userId != installationUserId {
                    installation["userId"] = userId
                }
            }

            try await installation.saveInBackground()
        } catch {
            logError(error)

            // HACK: If the installation object was deleted off the server,
            // then clear out the local installation object so we create a new one on next launch.
            // We're using the private string "_currentInstallation" because Parse prevents us from
            // deleting Installations normally.
            if error.code == PFErrorCode.errorObjectNotFound.rawValue {
                try? PFObject.unpinAllObjects(withName: "_currentInstallation")
            }
        }
    }

    // MARK: - Message Event Handling

    func handleRead(message: Messageable) {
        self.center.getDeliveredNotifications { [unowned self] delivered in
            Task.onMainActor {
                var identifiers: [String] = []
                var badgeCount = self.application?.applicationIconBadgeNumber ?? 0
                delivered.forEach { note in
                    if note.request.identifier == message.id {
                        identifiers.append(message.id)
                    }

                    if message.context == .timeSensitive {
                        badgeCount -= 1
                    }
                }

                self.application?.applicationIconBadgeNumber = badgeCount
                self.center.removeDeliveredNotifications(withIdentifiers: identifiers)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension UserNotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {

        // If the app is in the foreground, and is a new message, then check the interruption level to determine whether or not to show a banner. Don't show banners for non time-sensitive messages.
        if let app = self.application,
            await app.applicationState == .active,
            notification.request.content.categoryIdentifier == "MESSAGE_NEW" {

            if notification.request.content.interruptionLevel == .timeSensitive {
                return [.banner, .list, .sound, .badge]
            } else {
                return [.list, .sound, .badge]
            }
        }

        return [.banner, .list, .sound, .badge]
    }


    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        if let action = UserNotificationAction(rawValue: response.actionIdentifier) {
            self.handle(action: action, for: response)
        } else if let target = response.notification.deepLinkTarget {
            var deepLink = DeepLinkObject(target: target)
            deepLink.customMetadata = response.notification.customMetadata
            self.delegate?.userNotificationManager(willHandle: deepLink)
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                openSettingsFor notification: UNNotification?) {}

    private func handle(action: UserNotificationAction, for response: UNNotificationResponse) {
        switch action {
        case .sayHi:
            if let target = response.notification.deepLinkTarget {
                var deepLink = DeepLinkObject(target: target)
                deepLink.customMetadata = response.notification.customMetadata

                self.delegate?.userNotificationManager(willHandle: deepLink)
            }
        default:
            break
        }
    }
}
