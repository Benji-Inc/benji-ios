//
//  ChannelCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ChannelCoordinator: PresentableCoordinator<Void> {

    lazy var channelVC = ChannelViewController(delegate: self)

    init(router: Router,
         deepLink: DeepLinkable?,
         channelType: ChannelType?) {

        if case let .channel(channel) = channelType {
            ChannelSupplier.shared.set(activeChannel: DisplayableChannel(channelType: .channel(channel)))
        }
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.channelVC
    }
}

extension ChannelCoordinator: ChannelDetailViewControllerDelegate {

    func channelDetailViewControllerDidTapMenu(_ view: ChannelDetailViewController) {
        //Present channel menu
    }
}

extension ChannelCoordinator: ChannelViewControllerDelegate {

    func channelView(_ controller: ChannelViewController, didTapShare message: Messageable) {
        let items = [localized(message.text)]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.present(ac, animated: true, completion: nil)
    }
}
