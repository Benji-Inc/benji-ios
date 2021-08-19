//
//  HomeCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import PhotosUI

class HomeCoordinator: PresentableCoordinator<Void> {

    lazy var homeVC = HomeViewController()
    
    private var cancellables = Set<AnyCancellable>()

    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        ToastScheduler.shared.delegate = self

        self.checkForNotifications()

        self.homeVC.addButton.didSelect { [unowned self] in
            self.didTapAdd()
        }

        self.homeVC.collectionViewManager.didSelectReservations = { [unowned self] in
            self.didSelectReservations()
        }

        self.homeVC.collectionViewManager.$onSelectedItem.mainSink { selection in
            guard let value = selection else { return }
            switch value.section {
            case .notices:
                guard let notice = value.item as? SystemNotice else { return }
                self.handle(notice: notice)
            case .channels:
                guard let channel = value.item as? DisplayableChannel else { return }
                self.startChannelFlow(for: channel.channelType)
            }
        }.store(in: &self.cancellables)

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
        case .channel:
            if let channelId = deeplink.customMetadata["channelId"] as? String,
               let channel = ChannelSupplier.shared.getChannel(withSID: channelId) {
                self.startChannelFlow(for: channel.channelType)
            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {
                Task {
                    do {
                        let connection = try await Connection.cachedQuery(for: connectionId)
                        guard let channelId = connection.channelId,
                              let channel = ChannelSupplier.shared.getChannel(withSID: channelId) else {
                                  return
                              }

                        self.startChannelFlow(for: channel.channelType)
                    } catch {
                        logDebug(error)
                    }
                }
            }
        case .channels:
            break
        }
    }

    private func handle(notice: SystemNotice) {
        switch notice.type {
        case .alert:
            guard let channelId = notice.attributes?["channelId"] as? String, let channel = ChannelSupplier.shared.getChannel(withSID: channelId) else { return }
            self.startChannelFlow(for: channel.channelType)

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

    func startChannelFlow(for type: ChannelType?) {
        self.removeChild()
        var channel: DisplayableChannel?
        if let t = type {
            channel = DisplayableChannel(channelType: t)
        }
        let coordinator = ChannelCoordinator(router: self.router, deepLink: self.deepLink, channel: channel)
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

    func didSelectReservations() {
        self.removeChild()
        let coordinator = ReservationsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) {}
        self.router.present(coordinator, source: self.homeVC)
    }

    func didTapAdd() {
        self.removeChild()
        let coordinator = NewChannelCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {
                if result {
                    self.startChannelFlow(for: nil)
                }
            }
        }
        self.router.present(coordinator, source: self.homeVC)
    }

    private func showSoftAskNotifications(for status: UNAuthorizationStatus) {

        let alert = UIAlertController(title: "Notifications that don't suck.", message: "Most other social apps design their notifications to be vague in order to suck you in for as long as possible. Ours are not. Get reminders about things that YOU set, and recieve important messages from REAL people. Ours is a far better experience with them turned on.", preferredStyle: .alert)

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
