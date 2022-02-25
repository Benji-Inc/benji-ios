//
//  MessageDetailCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 2/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MessageDetailCoordinator: PresentableCoordinator<Void> {

    private lazy var messageVC = MessageDetailViewController(message: self.message, delegate: self)

    let message: Messageable

    init(with message: Messageable,
         router: Router,
         deepLink: DeepLinkable?) {

        self.message = message

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.messageVC
    }
}

extension MessageDetailCoordinator: MessageDetailViewControllerDelegate {

    func messageDetailViewController(_ controller: MessageDetailViewController,
                                     didSelectThreadFor message: Messageable) {

        let coordinator = ThreadCoordinator(with: message.streamCid,
                                            messageId: message.id,
                                            startingReplyId: nil,
                                            router: self.router,
                                            deepLink: self.deepLink)
        self.router.present(coordinator, source: self.messageVC)
        self.addChildAndStart(coordinator) { _ in }
    }
}
