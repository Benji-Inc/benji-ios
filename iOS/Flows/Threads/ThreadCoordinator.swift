//
//  ConversationThreadCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ThreadCoordinator: InputHandlerCoordinator<ConversationId>, DeepLinkHandler {
    
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
        
        self.threadVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first,
        case MessageSequenceItem.message(let cid, let messageID, _) = first else { return }
            
            self.presentMessageDetail(for: cid, messageId: messageID)
        }.store(in: &self.cancellables)
    }
    
    override func presentProfile(for person: PersonType) {
        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        self.present(coordinator) { [unowned self] result in
            self.finishFlow(with: result)
        }
    }
    
    func presentMessageDetail(for channelId: ChannelId, messageId: MessageId) {
        let message = Message.message(with: channelId, messageId: messageId)
        let coordinator = MessageDetailCoordinator(with: message,
                                                   router: self.router,
                                                   deepLink: self.deepLink)
        
        self.present(coordinator) { [unowned self] result in
            switch result {
            case .message(_):
                break
            case .reply(_):
                break
            case .conversation(let conversation):
                self.finishFlow(with: conversation)
            case .none:
                break
            }
        }
    }
    
    func handle(deepLink: DeepLinkable) {
        self.deepLink = deepLink
        guard let target = deepLink.deepLinkTarget else { return }
        
        switch target {
        case .profile:
            Task {
                guard let personId = self.deepLink?.personId,
                      let person = await PeopleStore.shared.getPerson(withPersonId: personId) else { return }
                self.presentProfile(for: person)
            }
        default:
            break
        }
    }
}
