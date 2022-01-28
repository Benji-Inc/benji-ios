//
//  UserNotificationManager+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 11/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications

extension UserNotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {

        guard notification.request.content.categoryIdentifier != "message.new" else { return [] }

        return [.banner, .list, .sound, .badge]
    }

    // NOTE: This delegate function seems to get called off the main thread some times which causes a
    // crash when bringing the app out of the background.
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {

        if let action = UserNotificationAction(rawValue: response.actionIdentifier) {
            self.handle(action: action, for: response)
        } else if let target = response.notification.deepLinkTarget {
            var deepLink = DeepLinkObject(target: target)
            deepLink.customMetadata = response.notification.customMetadata
            self.delegate?.userNotificationManager(willHandle: deepLink)
        }
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
