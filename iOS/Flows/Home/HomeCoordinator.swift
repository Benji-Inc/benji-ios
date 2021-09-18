//
//  HomeCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import PhotosUI

class HomeCoordinator: PresentableCoordinator<Void> {

    private lazy var homeVC: HomeViewController = {
        let vc = HomeViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        ToastScheduler.shared.delegate = self

//        self.checkForNotifications()

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .reservation:
            break // show a reservation alert.
        case .home:
            break
        case .login:
            break
        case .conversation:
            #warning("Replace")
//            if let conversationId = deeplink.customMetadata["conversationId"] as? String,
//               let conversation = ConversationSupplier.shared.getConversation(withSID: conversationId) {
//                self.startConversationFlow(for: conversation.conversationType)
//            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {
//                Task {
//                    do {
//                        let connection = try await Connection.getObject(with: connectionId)
//                        guard let conversationId = connection.conversationId,
//                              let conversation = ConversationSupplier.shared.getConversation(withSID: conversationId) else {
//                                  return
//                              }
//
//                        self.startConversationFlow(for: conversation.conversationType)
//                    } catch {
//                        logDebug(error)
//                    }
//                }
//            }
        case .conversations:
            break
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

    func startConversationFlow(for conversation: Conversation?) {
        self.removeChild()

        let coordinator = ConversationCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  conversation: conversation)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.homeVC, animated: true)
    }

    private func checkForNotifications() {
        Task {
            let settings = await UserNotificationManager.shared.getNotificationSettings()

            if settings.authorizationStatus != .authorized {
                self.showSoftAskNotifications(for: settings.authorizationStatus)
            }
        }
    }

    private func showSoftAskNotifications(for status: UNAuthorizationStatus) {

        let alert = UIAlertController(title: "Notifications that don't suck.",
                                      message: "Most other social apps design their notifications to be vague in order to suck you in for as long as possible. Ours are not. Get reminders about things that YOU set, and recieve important messages from REAL people. Ours is a far better experience with them turned on.",
                                      preferredStyle: .alert)

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

extension HomeCoordinator: HomeViewControllerDelegate {

    nonisolated func homeViewControllerDidTapAdd(_ controller: HomeViewController) {
        Task.onMainActor {
            self.didTapAdd()
        }
    }

    func didTapAdd() {
        self.removeChild()
        let coordinator = NewConversationCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {
                if result {
                    self.startConversationFlow(for: nil)
                }
            }
        }
        self.router.present(coordinator, source: self.homeVC)
    }

    nonisolated func homeViewControllerDidSelectReservations(_ controller: HomeViewController) {
        Task.onMainActor {
            self.didSelectReservations()
        }
    }

    func didSelectReservations() {
        self.removeChild()
        let coordinator = ReservationsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) {}
        self.router.present(coordinator, source: self.homeVC)
    }

    nonisolated func homeViewControllerDidSelect(item: HomeCollectionViewDataSource.ItemType) {
        Task.onMainActor {
            switch item {
            case .notice(let notice):
                self.handle(notice: notice)
            case .conversation(let conversation):
                self.startConversationFlow(for: conversation)
            }
        }
    }
}
