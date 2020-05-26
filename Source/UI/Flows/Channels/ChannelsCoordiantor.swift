//
//  ChannelsCoordiantor.swift
//  Benji
//
//  Created by Benji Dodgson on 12/21/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelsCoordinator: Coordinator<Void> {

    private let channelsVC: ChannelsViewController

    init(router: Router,
         deepLink: DeepLinkable?,
         channelsVC: ChannelsViewController) {

        self.channelsVC = channelsVC

        super.init(router: router, deepLink: deepLink)

        self.channelsVC.delegate = self 
    }
}

extension ChannelsCoordinator: ChannelsViewControllerDelegate {

    func channelsView(_ controller: ChannelsViewController, didSelect channelType: ChannelType) {
        self.startChannelFlow(for: channelType, with: controller)
    }

    func startChannelFlow(for type: ChannelType, with source: UIViewController) {
        let coordinator = ChannelCoordinator(router: self.router, deepLink: self.deepLink, channel: DisplayableChannel(channelType: type))
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: source, animated: true)
    }

    func channelsView(_ controller: ChannelsViewController, didSelect reservation: Reservation) {
        runMain {
            self.presentShare(for: reservation)
        }
    }

    private func presentShare(for reservation: Reservation) {

        if let _ = reservation.metadata {
            let ac = UIActivityViewController(activityItems: [reservation], applicationActivities: nil)
            self.router.navController.present(ac, animated: true)
        } else {
            reservation.prepareMetaData()
                .observeValue { (_) in
                    runMain {
                        let ac = UIActivityViewController(activityItems: [reservation], applicationActivities: nil)
                        ac.completionWithItemsHandler = { activityType, completed, items, error in
                            // do stuff
                        }
                        self.router.navController.present(ac, animated: true)
                    }
            }
        }
    }
}
