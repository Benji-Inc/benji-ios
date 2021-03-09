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

class FeedCoordinator: Coordinator<Void> {

    private let feedVC: FeedViewController

    init(router: Router,
         deepLink: DeepLinkable?,
         feedVC: FeedViewController) {

        self.feedVC = feedVC

        super.init(router: router, deepLink: deepLink)
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
            guard let reservation = post.reservation else { return }
            self.startReservationFlow(with: reservation)
        case .notificationPermissions:
            break
        case .connectionRequest:
            break // maybe go to channel? 
        case .meditation:
            self.showMeditation()
        }
    }

    private func startReservationFlow(with reservation: Reservation) {
        let coordinator = ReservationsCoordinator(reservation: reservation, router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (_) in}
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
