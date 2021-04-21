//
//  FeedCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization

class FeedCoordinator: PresentableCoordinator<Void> {

    lazy var feedVC = FeedViewController()

    override func toPresentable() -> DismissableVC {
        return self.feedVC
    }

    override func start() {
        self.feedVC.delegate = self
    }
}

extension FeedCoordinator: FeedViewControllerDelegate {

    func feedView(_ controller: FeedViewController, didSelect post: Postable) {
        switch post.type {
        case .timeSaved:
            break
        case .unreadMessages, .channelInvite:
            guard let channel = post.channel else { return }
            self.startChannelFlow(for: .channel(channel))
        case .inviteAsk:
            self.presentReservationsFlow(source: controller)
        case .notificationPermissions:
            break
        case .connectionRequest:
            break // maybe go to channel? 
        case .meditation:
            self.showMeditation()
        case .media:
            break 
        }
    }

    private func presentReservationsFlow(source: UIViewController) {
        let coordinator = ReservationsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (_) in}
        self.router.present(coordinator, source: source)
    }

    private func startChannelFlow(for type: ChannelType) {
        let coordinator = ChannelCoordinator(router: self.router, deepLink: self.deepLink, channel: DisplayableChannel(channelType: type))
        self.addChildAndStart(coordinator) { (_) in
            self.router.dismiss(source: coordinator.toPresentable())
        }
        self.router.present(coordinator, source: self.feedVC)
    }

    private func showMeditation() {
        let coordinator = MeditationCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (_) in
            self.router.dismiss(source: coordinator.toPresentable())
        }
        self.router.present(coordinator, source: self.feedVC)
    }
}
