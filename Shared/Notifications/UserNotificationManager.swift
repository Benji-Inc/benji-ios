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
import Parse
import Combine

protocol UserNotificationManagerDelegate: AnyObject {
    func userNotificationManager(willHandle: DeepLinkable)
}

class UserNotificationManager: NSObject {

    static let shared = UserNotificationManager()
    weak var delegate: UserNotificationManagerDelegate?

    private let center = UNUserNotificationCenter.current()

    var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        self.center.delegate = self
    }

    func getNotificationSettings() -> Future<UNNotificationSettings, Never> {
        return Future { promise in
            self.center.getNotificationSettings { (settings) in
                promise(.success(settings))
            }
        }
    }

    func silentRegister(withApplication application: UIApplication) {

        self.getNotificationSettings()
            .mainSink { (settings) in
                switch settings.authorizationStatus {
                case .authorized:
                    application.registerForRemoteNotifications()  // To update our token
                case .provisional:
                    application.registerForRemoteNotifications()  // To update our token
                case .notDetermined:
                    self.register(with: [.alert, .sound, .badge, .provisional], application: application)
                        .mainSink { (_) in }.store(in: &self.cancellables)
                case .denied, .ephemeral:
                    return
                @unknown default:
                    return
                }
            }.store(in: &self.cancellables)
    }

    @discardableResult
    func register(with options: UNAuthorizationOptions = [.alert, .sound, .badge],
                  application: UIApplication) -> Future<Bool, Never> {

        return Future { promise in
            self.requestAuthorization(with: options)
                .mainSink { (granted) in

                    if granted {
                        application.registerForRemoteNotifications()  // To update our token
                    }
                    promise(.success(granted))
                }.store(in: &self.cancellables)
        }
    }

    private func requestAuthorization(with options: UNAuthorizationOptions = [.alert, .sound, .badge]) -> Future<Bool, Never> {
        return Future { promise in
            self.center.requestAuthorization(options: options) { (granted, error) in
                if granted {
                    let userCategories = UserNotificationCategory.allCases.map { userCategory in
                        return userCategory.category
                    }
                    let categories: Set<UNNotificationCategory> = Set.init(userCategories)
                    self.center.setNotificationCategories(categories)
                }

                promise(.success(granted))
            }
        }
    }

    func removeNonEssentialPendingNotifications() {
        self.center.getPendingNotificationRequests { requests in

            var identifiers: [String] = []

            requests.forEach { request in
                if let category = UserNotificationCategory(rawValue: request.content.categoryIdentifier) {
                    if category != .connectionRequest {
                        identifiers.append(request.identifier)
                    }
                } else {
                    identifiers.append(request.identifier)
                }
            }

            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    func removeAllPendingNotificationRequests() {
        self.center.removeAllPendingNotificationRequests()
    }

    #if !NOTIFICATION
    func resetBadgeCount() {
        let count = UIApplication.shared.applicationIconBadgeNumber
        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    #endif

    @discardableResult
    func handle(userInfo: [AnyHashable: Any]) -> Bool {
        guard let data = userInfo["data"] as? [String: Any],
              let note = UserNotificationFactory.createNote(from: data) else { return false }

        self.schedule(note: note)
        return true
    }

    @discardableResult
    func schedule(note: UNNotificationRequest) -> Future<Void, Never> {
        return Future { promise in
            self.center.add(note, withCompletionHandler: { (_) in
                promise(.success(()))
            })
        }
    }

    func registerPush(from deviceToken: Data) {
        PFInstallation.getCurrent()
            .mainSink { result in
                switch result {
                case .success(let current):
                    current.badge = 0
                    current.setDeviceTokenFrom(deviceToken)
                    if current["userId"].isNil {
                        current["userId"] = User.current()?.objectId
                    }
                    current.saveInBackground()
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }
}
