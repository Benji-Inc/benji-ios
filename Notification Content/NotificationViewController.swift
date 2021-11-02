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

    lazy var connectionRequestView: ConnectionRequestView = {
        let view = ConnectionRequestView()
        view.didUpdateConnection = { [unowned self] updatedConnection in
            self.extensionContext?.notificationActions = [UserNotificationAction.sayHi.action]
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if Parse.currentConfiguration == nil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                configuration.containingApplicationBundleIdentifier = "com.Jibber-Inc.Jibber"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
                configuration.isLocalDatastoreEnabled = true
            }))
        }
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let category
                = UserNotificationCategory(rawValue: notification.request.content.categoryIdentifier) else { return }

        switch category {
        case .connectionRequest:
            guard let connectionId = notification.connectionId else { return }
            self.view.addSubview(self.connectionRequestView)

            Task {
                guard let connection = try? await Connection.localThenNetworkQuery(for: connectionId) else {
                    return
                }

                await self.connectionRequestView.configure(with: connection)
            }
        case .connnectionConfirmed:
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

        self.connectionRequestView.expandToSuperviewSize()
    }
}
