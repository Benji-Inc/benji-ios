//
//  NotificationViewController.swift
//  OursNotificationContent
//
//  Created by Benji Dodgson on 2/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import Combine
import Parse

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        if Parse.currentConfiguration == nil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                configuration.containingApplicationBundleIdentifier = Config.shared.environment.bundleId
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appId
                configuration.isLocalDatastoreEnabled = true
            }))
        }
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let category
                = UserNotificationCategory(rawValue: notification.request.content.categoryIdentifier) else { return }

        switch category {
        case .connectionRequest:
            break
        case .connnectionConfirmed:
            break
        case .newMessage:
            break 
        }

        self.view.layoutNow()
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {

        if let _ = UserNotificationAction.init(rawValue: response.actionIdentifier) {
            completion(.dismissAndForwardAction)
        } else {
            completion(.doNotDismiss)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
}
