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
import SideMenu
import PhotosUI

class HomeCoordinator: PresentableCoordinator<Void> {

    private lazy var profileVC = ProfileViewController(with: User.current()!)
    lazy var homeVC = HomeViewController()

    lazy var profileCoordinator = ProfileCoordinator(router: self.router,
                                                     deepLink: self.deepLink,
                                                     vc: self.profileVC)
    
    private var cancellables = Set<AnyCancellable>()

    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        ToastScheduler.shared.delegate = self

        self.checkForNotifications()

        self.homeVC.addButton.didSelect { [unowned self] in
           // self.delegate?.channelsViewControllerDidTapAdd(self)
        }

        self.homeVC.tabView.didSelectProfile = { [unowned self] in
            self.addProfile()
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

        let leftMenuNavigationController = SideNavigationController(with: self.profileVC)
        leftMenuNavigationController.sideMenuDelegate = self
        SideMenuManager.default.leftMenuNavigationController = leftMenuNavigationController

        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.homeVC.view)
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
                Connection.cachedQuery(for: connectionId)
                    .mainSink { result in
                        switch result {
                        case .success(let connection):
                            if let channelId = connection.channelId, let channel = ChannelSupplier.shared.getChannel(withSID: channelId) {
                                self.startChannelFlow(for: channel.channelType)
                            }
                        case .error(_):
                            break
                        }
                    }.store(in: &self.cancellables)
            }
        case .profile:
            self.addProfile()
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
        UserNotificationManager.shared.getNotificationSettings()
            .mainSink { settings in
                if settings.authorizationStatus != .authorized {
                    self.showSoftAskNotifications(for: settings.authorizationStatus)
                }
            }.store(in: &self.cancellables)
    }

//    func channelsViewConrollerDidSelectReservations(_ controller: ChannelsViewController) {
//        let coordinator = ReservationsCoordinator(router: self.router, deepLink: self.deepLink)
//        self.addChildAndStart(coordinator) {}
//       // self.router.present(coordinator, source: self.channelsVC)
//    }

//    func channelsViewControllerDidTapAdd(_ controller: ChannelsViewController) {
//        let coordinator = NewChannelCoordinator(router: self.router, deepLink: self.deepLink)
//        self.addChildAndStart(coordinator) { result in
//            coordinator.toPresentable().dismiss(animated: true) {
//                if result {
//                    self.startChannelFlow(for: nil)
//                }
//            }
//        }
//        self.router.present(coordinator, source: self.channelsVC)
//    }

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
                UserNotificationManager.shared.register(application: UIApplication.shared)
            }
        }

        let cancel = UIAlertAction(title: "Maybe Later", style: .cancel) { action in}

        alert.addAction(cancel)
        alert.addAction(allow)

        self.router.topmostViewController.present(alert, animated: true, completion: nil)
    }
}
