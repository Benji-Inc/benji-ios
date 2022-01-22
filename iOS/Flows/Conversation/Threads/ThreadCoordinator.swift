//
//  ConversationThreadCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ThreadCoordinator: PresentableCoordinator<Void> {

    lazy var threadVC = ThreadViewController(channelID: self.channelId,
                                             messageID: self.messageId,
                                             startingReplyId: self.startingReplyId)
    let messageId: MessageId
    let channelId: ChannelId
    let startingReplyId: MessageId?

    init(with channelId: ChannelId,
         messageId: MessageId,
         startingReplyId: MessageId?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.channelId = channelId
        self.messageId = messageId
        self.startingReplyId = startingReplyId

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.threadVC
    }
    
    override func start() {
        super.start()
        
        self.threadVC.swipeInputDelegate.didTapAvatar = { [unowned self] in
            self.presentProfilePicture()
        }
    }
    
    func presentProfilePicture() {
        let vc = ModalPhotoViewController()
        
        // Because of how the People are presented, we need to properly reset the KeyboardManager.
        vc.dismissHandlers.append { [unowned self] in
            self.threadVC.becomeFirstResponder()
        }
        
        vc.onDidComplete = { _ in
            vc.dismiss(animated: true, completion: nil)
        }

        self.threadVC.resignFirstResponder()
        self.router.present(vc, source: self.threadVC)
    }
}
