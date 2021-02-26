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
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        if let action = UserNotificationAction.init(rawValue: response.actionIdentifier) {
            self.handle(action: action, for: response.notification.request.content.userInfo)
        } else if let target = response.notification.deepLinkTarget {
            var deepLink = DeepLinkObject(target: target)
            deepLink.customMetadata = response.notification.customMetadata
            self.delegate?.userNotificationManager(willHandle: deepLink)
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {}

    private func handle(action: UserNotificationAction, for userInfo: [AnyHashable: Any]) {
        switch action {
        case .acceptConnection:
            guard let connectionId = userInfo["connectionId"] as? String else { return }
            UpdateConnection(connectionId: connectionId, status: .accepted).makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink().store(in: &self.cancellables)
        case .declineConnection:
            guard let connectionId = userInfo["connectionId"] as? String else { return }
            UpdateConnection(connectionId: connectionId, status: .accepted).makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink().store(in: &self.cancellables)
        }
    }
}
