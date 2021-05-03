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
import Photos

class HomeCoordinator: PresentableCoordinator<Void> {

    private lazy var profileVC = ProfileViewController(with: User.current()!)
    private lazy var channelsVC = ChannelsViewController()
    private lazy var homeVC = HomeViewController()
    private lazy var imagePickerVC = ImagePickerViewController()

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

        self.homeVC.didTapAddRitual = { [unowned self] in
            self.showRitual()
        }

        self.homeVC.willPresentFeedForUser = { [unowned self] user in
            self.presentFeed(for: user)
        }

        self.homeVC.didSelectPhotoLibrary = { [unowned self] in
            self.presentPicker(for: .photoLibrary)
        }

        self.homeVC.archivesVC.didSelectPost = { [unowned self] post in
            self.show(post: post)
        }

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
        case .ritual:
            self.startRitualFlow()
        case .profile:
            self.addProfile()
        case .feed:
            break
        case .channels:
            self.addChannels()
        }
    }

    private func show(post: Post) {
        let vc = PostMediaViewController(with: post)
        self.router.present(vc, source: self.homeVC)
    }

    private func showRitual() {
        self.removeChild()
        let coordinator = RitualCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (_) in }
        self.router.present(coordinator, source: self.homeVC)
    }

    private func presentFeed(for user: User) {
        self.removeChild()
        self.homeVC.feedCollectionVC.collectionViewManager.unselectAllItems()
        let coordinator = FeedCoordinator(router: self.router, deepLink: self.deepLink)
        coordinator.feedVC.didTapDone = {
            coordinator.feedVC.dismiss(animated: true) {
                coordinator.feedVC.cancellables.forEach { cancellable in
                    cancellable.cancel()
                }
                coordinator.feedVC.removeFromParent()
            }
        }
        self.addChildAndStart(coordinator) { (_) in }
        self.router.present(coordinator, source: self.homeVC, cancelHandler: nil, animated: true) {
            coordinator.feedVC.loadPosts(for: user)
        }
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

    private func startRitualFlow() {
        let coordinator = RitualCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (result) in }
        self.router.present(coordinator, source: self.homeVC)
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

extension HomeCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private func presentPicker(for type: UIImagePickerController.SourceType) {
        guard self.router.topmostViewController != self.imagePickerVC, !self.imagePickerVC.isBeingPresented else { return }

        self.imagePickerVC.sourceType = type
        self.imagePickerVC.delegate = self 
        self.homeVC.present(self.imagePickerVC, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        defer {
            self.imagePickerVC.dismiss(animated: true, completion: nil)
        }

        guard let image = info[.originalImage] as? UIImage else {
            print("Image not found!")
            return
        }

        self.homeVC.createVC.show(image: image)
    }
}

private class ImagePickerViewController: UIImagePickerController, Dismissable {
    var dismissHandlers: [DismissHandler] = []

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }
}

extension HomeCoordinator: ToastSchedulerDelegate {

    func didInteractWith(type: ToastType) {
        switch type {
        case .error(_):
            break
        case .basic(_, _, _):
            break
        }
    }
}
