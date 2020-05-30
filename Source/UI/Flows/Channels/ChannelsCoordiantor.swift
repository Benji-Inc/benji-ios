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

    func channelsView(_ controller: ChannelsViewController, didSelect reservation: Reservation, channelId: String) {

        if let _ = reservation.metadata {
            self.presentShare(for: reservation)
        } else {
            reservation.prepareMetaData(with: channelId)
                .observeValue { [unowned self] (_) in
                    self.presentShare(for: reservation)
            }
        }
    }

    private func presentShare(for reservation: Reservation) {
        runMain {
            let ac = UIActivityViewController(activityItems: [reservation], applicationActivities: nil)
            ac.completionWithItemsHandler = { activityType, completed, items, error in
                self.showAlert()
            }
            self.router.navController.present(ac, animated: true)
        }
    }

    private func showAlert() {
        let alert = UIAlertController(title: "Invitation Sent",
                                      message: "Your invation has been sent. As soon as someone register's using your link, a conversation will be created between you both and you will be able to communicate using Benji.",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in

        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }
}
