//
//  UNNotificationContent+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 4/19/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications
import StreamChat

enum NotificationContentKey: String {
    case target = "target"
    case group = "group"
    case deeplink = "deeplink"
    case identifier = "identifier"
    case body = "body"
    case title = "title"
    case subtitle = "subtitle"
    case trigger = "trigger"
    case category = "categoryIdentifier"
    case thread = "threadIdentifier"
    case conversationId = "conversationId"
    case messageId = "messageId"
    case connectionId = "connectionId"
}

extension UNNotificationContent {

    var messageId: String? {
        guard let value: String = self.value(for: .messageId) else { return nil }
        return value
    }

    var conversationId: String? {
        if let stream = self.userInfo["stream"] as? [String: Any],
           let cid = stream["cid"] as? String {
            return cid
        } else if let value: String = self.value(for: .conversationId) {
            return value
        } else {
            return nil
        }
    }

    var connectionId: String? {
        guard let value: String = self.value(for: .connectionId) else { return nil }
        return value
    }

    var deepLinkTarget: DeepLinkTarget? {
        if let stream = self.userInfo["stream"] as? [String: Any],
           let _ = stream["cid"] as? String {
            return DeepLinkTarget.conversation

        } else if let value: String = self.value(for: .target) {
            return DeepLinkTarget(rawValue: value)
        } else {
            return nil
        }
    }

    var deeplinkURL: URL? {
        guard let value: String = self.value(for: .deeplink) else { return nil }
        return URL(string: value)
    }

    var identifier: String? {
        return self.value(for: .identifier)
    }

    func value<Type>(for key: NotificationContentKey) -> Type? {
        guard let data = self.userInfo["data"] as? [String: Any] else { return nil }
        return data[key.rawValue] as? Type
    }

    func valueFrom<Type>(data: [String: Any], for key: NotificationContentKey) -> Type? {
        return data[key.rawValue] as? Type
    }
}

extension UNMutableNotificationContent {

    func setUserInfo(from data: [String: Any]) {
        self.setValue(for: .target, from: data)
        self.setValue(for: .deeplink, from: data)
        self.setValue(for: .identifier, from: data)

        if let subtitle: String = self.valueFrom(data: data, for: .subtitle) {
            self.subtitle = subtitle
        }

        if let category: String = self.valueFrom(data: data, for: .category) {
            self.categoryIdentifier = category
        }

        if let thread: String = self.valueFrom(data: data, for: .thread) {
            self.threadIdentifier = thread
        }

        self.userInfo = data
    }

    func setValue(for key: NotificationContentKey, from data: [String: Any]) {
        self.userInfo[key.rawValue] = data[key.rawValue]
    }

    func setData(value: Any, for key: NotificationContentKey) {
        self.userInfo["data"] = [key.rawValue: value]
    }
}

