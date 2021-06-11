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
    private lazy var channelsVC = ChannelsViewController()
    private lazy var homeVC = HomeViewController()
    private lazy var imagePickerVC: PHPickerViewController = {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 1
        config.filter = .any(of: [.images, .videos])
        let vc = PHPickerViewController.init(configuration: config)
        return vc
    }()

    private lazy var channelsCoordinator = ChannelsCoordinator(router: self.router,
                                                               deepLink: self.deepLink,
                                                               vc: self.channelsVC)
    private lazy var profileCoordinator = ProfileCoordinator(router: self.router,
                                                             deepLink: self.deepLink,
                                                             vc: self.profileVC)
    
    private var cancellables = Set<AnyCancellable>()

    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        ToastScheduler.shared.delegate = self

        self.channelsVC.subscribeToUpdates()
        self.checkForNotifications()

        self.homeVC.didTapProfile = { [unowned self] in
            self.addProfile()
        }

        self.homeVC.didTapChannels = { [unowned self] in
            self.addChannels()
        }

        self.homeVC.noticesCollectionVC.collectionViewManager.$onSelectedItem.mainSink { selection in
            guard let item = selection?.item as? SystemNotice else { return }
            self.handle(notice: item)
        }.store(in: &self.cancellables)

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }

        let leftMenuNavigationController = SideNavigationController(with: self.profileVC)
        leftMenuNavigationController.sideMenuDelegate = self
        SideMenuManager.default.leftMenuNavigationController = leftMenuNavigationController

        let rightMenuNavigationController = SideNavigationController(with: self.channelsVC)
        rightMenuNavigationController.sideMenuDelegate = self
        SideMenuManager.default.rightMenuNavigationController = rightMenuNavigationController

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
            self.addChannels()
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

    private func showRitual() {
        self.removeChild()
        let coordinator = RitualCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (_) in }
        self.router.present(coordinator, source: self.homeVC)
    }

    private func addChannels(shouldPresent: Bool = true) {
        self.removeChild()
        self.addChildAndStart(self.channelsCoordinator) { (_) in }
        if let right = SideMenuManager.default.rightMenuNavigationController, shouldPresent {
            self.homeVC.present(right, animated: true, completion: nil)
        }
    }

    private func addProfile(shouldPresent: Bool = true) {
        self.removeChild()

        self.addChildAndStart(self.profileCoordinator) { (_) in }
        if let left = SideMenuManager.default.leftMenuNavigationController, shouldPresent {
            self.homeVC.present(left, animated: true, completion: nil)
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

    private func showLockedNotification(for post: Post) {

        User.current()?.ritual?.retrieveDataIfNeeded()
            .mainSink(receivedResult: { result in
                switch result {
                case .success(let ritual):
                    if let date = ritual.date {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let string = formatter.string(from: date)

                        let alert = UIAlertController(title: "Post locked.", message: "This post is locked until your feed is made available at \(string).", preferredStyle: .alert)

                        let cancel = UIAlertAction(title: "Ok", style: .cancel) { action in}

                        alert.addAction(cancel)

                        self.router.topmostViewController.present(alert, animated: true, completion: nil)
                    }

                case .error(_):
                    break
                }
            }).store(in: &self.cancellables)
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
                UserNotificationManager.shared.register(application: UIApplication.shared)
            }
        }

        let cancel = UIAlertAction(title: "Maybe Later", style: .cancel) { action in}

        alert.addAction(cancel)
        alert.addAction(allow)

        self.router.topmostViewController.present(alert, animated: true, completion: nil)
    }
}

extension HomeCoordinator: SideMenuNavigationControllerDelegate {

    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animate(show: false)
    }

    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {
        if let _ = menu.viewControllers.first as? ProfileViewController {
            self.addProfile(shouldPresent: false)
        } else if let _ = menu.viewControllers.first as? ChannelsViewController {
            self.addChannels(shouldPresent: false)
        }
    }

    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {

    }

    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animate(show: true)
    }
}

extension HomeCoordinator: ToastSchedulerDelegate {

    func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        if let link = deeplink {
            self.handle(deeplink: link)
        }
    }
}
