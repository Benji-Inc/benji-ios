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

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?

    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body

        let actions: [UserNotificationAction] = [.acceptConnection, .declineConnection]
        self.extensionContext?.notificationActions = actions.map({ userAction in
            return userAction.action
        })
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {

        if let action = UserNotificationAction.init(rawValue: response.actionIdentifier) {
            self.handle(action: action, for: response.notification.request.content.userInfo)
        }

        completion(.doNotDismiss)
    }

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
