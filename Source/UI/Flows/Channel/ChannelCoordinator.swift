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
         channel: DisplayableChannel?) {

        if let c = channel {
            ChannelSupplier.shared.set(activeChannel: c)
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
        var items: [Any] = []
        switch message.kind {
        case .text(let text):
            items = [text]
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }

        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.present(ac, animated: true, completion: nil)
    }
}
