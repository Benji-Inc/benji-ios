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

    var cancellables = Set<AnyCancellable>()

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
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await withCheckedContinuation({ continuation in
            self.center.getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        })
    }

    func removeAllPendingNotificationRequests() {
        self.center.removeAllPendingNotificationRequests()
    }

    func schedule(note: UNNotificationRequest) async {
        try? await self.center.add(note)
    }

    func registerPush(from deviceToken: Data) async {
        do {
            let installation = try await PFInstallation.getCurrent()
            installation.badge = 0
            installation.setDeviceTokenFrom(deviceToken)
            if installation["userId"].isNil {
                installation["userId"] = User.current()?.objectId
            }
            
            try await installation.saveInBackground()
        } catch {
            logError(error)
        }
    }
}
