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
        view.didUpdateConnection = { [unowned self] _ in
            self.extensionContext?.dismissNotificationContentExtension()
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if Parse.currentConfiguration == nil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.applicationGroupIdentifier = "group.com.BENJI"
                configuration.containingApplicationBundleIdentifier = "com.Benji.Ours"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
                configuration.isLocalDatastoreEnabled = true
            }))
        }
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let category = UserNotificationCategory.init(rawValue: notification.request.content.categoryIdentifier) else { return }

        switch category {
        case .connectionRequest:
            guard let connectionId = notification.connectionId else { return }
            self.view.addSubview(self.connectionRequestView)
            Connection.localThenNetworkQuery(for: connectionId)
                .mainSink { connection in
                    self.connectionRequestView.configure(with: connection)
                }.store(in: &self.cancellables)
        }

        self.view.layoutNow()
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {

        completion(.doNotDismiss)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.connectionRequestView.expandToSuperviewSize()
    }
}
