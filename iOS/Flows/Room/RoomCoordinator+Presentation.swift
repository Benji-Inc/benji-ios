//
//  RoomCoordinator+Presentation.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension RoomCoordinator {
    
    func presentConversation(with cid: ConversationId?, messageId: MessageId?) {
        
        let coordinator = ConversationListCoordinator(router: self.router,
                                                      deepLink: self.deepLink,
                                                      conversationMembers: [],
                                                      startingConversationId: cid,
                                                      startingMessageId: messageId)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in })
        self.router.present(coordinator, source: self.roomVC, cancelHandler: nil, animated: true, completion: nil)
    }
}
