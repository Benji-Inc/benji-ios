//
//  ChannelsCoordiantor.swift
//  Benji
//
//  Created by Benji Dodgson on 12/21/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelsCoordinator: PresentableCoordinator<Void> {

    private let channelsVC: ChannelsViewController

    init(router: Router, deepLink: DeepLinkable?, vc: ChannelsViewController) {
        self.channelsVC = vc
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.channelsVC
    }

    override func start() {
        self.channelsVC.delegate = self 
    }
}

extension ChannelsCoordinator: ChannelsViewControllerDelegate {

    func channelsView(_ controller: ChannelsViewController, didSelect channelType: ChannelType) {
        self.startChannelFlow(for: channelType)
    }

    func startChannelFlow(for type: ChannelType?) {
        var displayableChannel: DisplayableChannel?
        if let type = type {
            displayableChannel = DisplayableChannel(channelType: type)
        }
        let coordinator = ChannelCoordinator(router: self.router, deepLink: self.deepLink, channel: displayableChannel)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.channelsVC, animated: true)
    }

    func channelsView(_ controller: ChannelsViewController, didSelect reservation: Reservation) {
        let coordinator = ReservationsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) {}
        self.router.present(coordinator, source: self.channelsVC)
    }

    func channelsViewControllerDidTapAdd(_ controller: ChannelsViewController) {
        let coordinator = NewChannelCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {
                if result {
                    self.startChannelFlow(for: nil)
                }
            }
        }
        self.router.present(coordinator, source: self.channelsVC)
    }
}
