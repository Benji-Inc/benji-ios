//
//  HomeCoordinator+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension HomeCoordinator: ToastSchedulerDelegate {
    
    nonisolated func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        Task.onMainActor {
            guard let link = deeplink else { return }
            self.handle(deeplink: link)
        }
    }
}

extension HomeCoordinator: HomeViewControllerDelegate {

    nonisolated func homeViewControllerDidSelect(item: HomeCollectionViewDataSource.ItemType) {
        Task.onMainActor {
            switch item {
            case .notice(let notice):
                self.handle(notice: notice)
            }
        }
    }

    private func handle(notice: SystemNotice) {
        switch notice.type {
        case .alert:
            #warning("Replace")
//            guard let conversationId = notice.attributes?["conversationId"] as? String, let conversation = ConversationSupplier.shared.getConversation(withSID: conversationId) else { return }
//            self.startConversationFlow(for: conversation.conversationType)
            break
        case .connectionRequest:
            break
        case .connectionConfirmed:
            break
        case .messageRead:
            break
        case .system:
            break
        }
    }

    func checkForNotifications() {
        Task {
            let settings = await UserNotificationManager.shared.getNotificationSettings()

            if settings.authorizationStatus != .authorized {
                self.showSoftAskNotifications(for: settings.authorizationStatus)
            }
        }
    }

    private func showSoftAskNotifications(for status: UNAuthorizationStatus) {

        let alert = UIAlertController(title: "Notifications that don't suck.", message: "Most other social apps design their notifications to be vague in order to suck you in for as long as possible. Ours are not. Get reminders about things that YOU set, and recieve important messages from REAL people. Jibber is a far better experience with them turned on.", preferredStyle: .alert)

        let allow = UIAlertAction(title: "Allow", style: .default) { action in
            if status == .denied {
                if let bundleIdentifier = Bundle.main.bundleIdentifier, let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
                    if UIApplication.shared.canOpenURL(appSettings) {
                        UIApplication.shared.open(appSettings)
                    }
                }
            } else {
                Task {
                    await UserNotificationManager.shared.register(application: UIApplication.shared)
                }
            }
        }

        let cancel = UIAlertAction(title: "Maybe Later", style: .cancel) { action in}

        alert.addAction(cancel)
        alert.addAction(allow)

        self.router.topmostViewController.present(alert, animated: true, completion: nil)
    }
}

