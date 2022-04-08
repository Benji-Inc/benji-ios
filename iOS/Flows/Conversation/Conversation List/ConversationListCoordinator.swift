//
//  ConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import Combine
import StreamChat
import Localization
import Intents

class ConversationListCoordinator: InputHandlerCoordinator<Void> {
    
    var listVC: ConversationListViewController {
        return self.inputHandlerViewController as! ConversationListViewController
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         conversationMembers: [ConversationMember],
         startingConversationId: ConversationId?,
         startingMessageId: MessageId?) {
        
        let vc = ConversationListViewController(members: conversationMembers,
                                                startingConversationID: startingConversationId,
                                                startingMessageID: startingMessageId)

        super.init(with: vc, router: router, deepLink: deepLink)

        vc.messageCellDelegate = self
    }

    override func start() {
        super.start()
        
        self.listVC.headerVC.roomsButton.didSelect { [unowned self] in
            self.finishFlow(with: ())
        }
        
        self.listVC.headerVC.jibImageView.didSelect { [unowned self] in
            self.showWallet()
        }
        
        self.listVC.headerVC.button.didSelect { [unowned self] in
            self.presentConversationDetail()
        }
        
        self.listVC.dataSource.handleAddPeopleSelected = { [unowned self] in
            Task {
                try await self.createNewConversation()
                Task.onMainActor {
                    self.presentPeoplePicker()
                }
            }
        }
        
        self.listVC.dataSource.handleInvestmentSelected = { [unowned self] in
            self.presentEmailAlert() 
        }
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            let messageID = deeplink.messageId
            guard let cid = deeplink.conversationId else { break }
            Task {
                await self.listVC.scrollToConversation(with: cid,
                                                       messageId: messageID,
                                                       animateScroll: false,
                                                       animateSelection: true)
            }.add(to: self.taskPool)
        case .wallet:
            self.showWallet()
        default:
            break
        }
    }
    
    override func presentProfile(for person: PersonType) {
        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        self.present(coordinator) { [unowned self] result in
            Task.onMainActorAsync {
                await self.listVC.scrollToConversation(with: result, messageId: nil, animateScroll: false)
            }
        }
    }
    
    func createNewConversation() async throws {
        let username = User.current()?.initials ?? ""
        let channelId = ChannelId(type: .messaging, id: username+"-"+UUID().uuidString)
        let userIDs = Set([User.current()!.objectId!])
        let controller = try ChatClient.shared.channelController(createChannelWithId: channelId,
                                                                 name: nil,
                                                                 imageURL: nil,
                                                                 team: nil,
                                                                 members: userIDs,
                                                                 isCurrentUserMember: true,
                                                                 messageOrdering: .bottomToTop,
                                                                 invites: [],
                                                                 extraData: [:])
        
        try await controller.synchronize()
        AnalyticsManager.shared.trackEvent(type: .conversationCreated, properties: nil)
        ConversationsManager.shared.activeConversation = controller.conversation
    }
    
    override func messageCell(_ cell: MessageCell, didTapMessage messageInfo: (ConversationId, MessageId)) {
        let message = Message.message(with: messageInfo.0, messageId: messageInfo.1)

        if let parentId = message.parentMessageId {
            self.presentThread(for: messageInfo.0, messageId: parentId, startingReplyId: messageInfo.1)
        } else {
            self.presentMessageDetail(for: messageInfo.0, messageId: messageInfo.1)
        }
    }
}
