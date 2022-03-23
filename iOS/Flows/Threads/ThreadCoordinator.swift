//
//  ConversationThreadCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ThreadCoordinator: InputHandlerCoordinator<ConversationId> {
    
    var threadVC: ThreadViewController {
        return self.inputHandlerViewController as! ThreadViewController
    }

    init(with channelId: ChannelId,
         messageId: MessageId,
         startingReplyId: MessageId?,
         router: Router,
         deepLink: DeepLinkable?) {
        
        let vc = ThreadViewController(channelID: channelId,
                                      messageID: messageId,
                                      startingReplyId: startingReplyId)

        super.init(with: vc, router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.threadVC
    }
    
    override func start() {
        super.start()
        
        self.threadVC.swipeInputDelegate.didTapAvatar = { [unowned self] in
            self.presentProfile(for: User.current()!)
        }
    }
    
    func presentProfile(for person: PersonType) {
        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        self.present(coordinator) { [unowned self] result in
            self.finishFlow(with: result)
        }
    }
}
