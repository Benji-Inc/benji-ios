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

class HomeCoordinator: PresentableCoordinator<Void> {

    private lazy var profileVC = ProfileViewController(with: User.current()!)
    private lazy var channelsVC = ChannelsViewController()
    private lazy var homeVC = HomeViewController()
    
    private var cancellables = Set<AnyCancellable>()

    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        self.addFeedCoordinator()
        self.channelsVC.subscribeToUpdates()

        self.homeVC.didTapProfile = { [unowned self] in
            self.presentProfile()
        }

        self.homeVC.didTapChannels = { [unowned self] in
            self.presentChannels()
        }

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }

        let leftMenuNavigationController = SideNavigationController(with: self.profileVC)
        leftMenuNavigationController.sideMenuDelegate = self
        SideMenuManager.default.leftMenuNavigationController = leftMenuNavigationController

        let rightMenuNavigationController = SideNavigationController(with: self.channelsVC, width: 140)
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
            self.presentProfile()
        case .feed:
            break
        case .channels:
            self.presentChannels()
        }
    }

    private func addFeedCoordinator() {
        self.removeChild()
        let coordinator = FeedCoordinator(router: self.router,
                                          deepLink: self.deepLink,
                                          feedVC: self.homeVC.feedVC)
        self.addChildAndStart(coordinator) { (_) in }
    }

    private func presentChannels() {
        self.removeChild()
        let coordinator = ChannelsCoordinator(router: self.router,
                                              deepLink: self.deepLink,
                                              vc: self.channelsVC)
        self.channelsVC.delegate = coordinator
        self.addChildAndStart(coordinator) { (_) in }
        if let right = SideMenuManager.default.rightMenuNavigationController {
            self.homeVC.present(right, animated: true, completion: nil)
        }
    }

    private func presentProfile() {
        self.removeChild()
        let coordinator = ProfileCoordinator(router: self.router,
                                             deepLink: self.deepLink,
                                             vc: self.profileVC)
        self.profileVC.delegate = coordinator
        self.addChildAndStart(coordinator) { (_) in }
        if let left = SideMenuManager.default.leftMenuNavigationController {
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
}

extension HomeCoordinator: SideMenuNavigationControllerDelegate {

    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animateTabView(shouldShow: false)
    }

    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {

    }

    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {

    }

    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animateTabView(shouldShow: true)
    }
}
