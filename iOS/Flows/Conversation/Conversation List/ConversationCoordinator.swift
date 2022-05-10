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

/// A coordinator for displaying a single conversation.
class ConversationCoordinator: InputHandlerCoordinator<Void>, DeepLinkHandler {
    
    var listVC: ConversationViewController {
        return self.inputHandlerViewController as! ConversationViewController
    }
    
    init(router: Router,
         deepLink: DeepLinkable?,
         cid: ConversationId,
         startingMessageId: MessageId?,
         openReplies: Bool = false) {
        
        let vc = ConversationViewController(cid: cid,
                                            startingMessageID: startingMessageId,
                                            openReplies: openReplies)
        
        super.init(with: vc, router: router, deepLink: deepLink)
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
    
    func handle(deepLink: DeepLinkable) {
        self.deepLink = deepLink
        
        guard let target = deepLink.deepLinkTarget else { return }
        
        switch target {
        case .conversation:
            let messageID = deepLink.messageId
            guard let cid = deepLink.conversationId else { break }
            Task {
                await self.listVC.scrollToConversation(with: cid,
                                                       messageId: messageID,
                                                       animateScroll: false,
                                                       animateSelection: true)
            }.add(to: self.taskPool)
        case .wallet:
            self.showWallet()
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
    
    override func presentProfile(for person: PersonType) {
        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        self.present(coordinator) { [unowned self] result in
            switch result {
            case .conversation(let cid):
                Task.onMainActorAsync {
                    await self.listVC.scrollToConversation(with: cid, messageId: nil, animateScroll: false)
                }
            case .openReplies(let cid, let messageId):
                Task.onMainActorAsync {
                    await self.listVC.scrollToConversation(with: cid,
                                                           messageId: messageId,
                                                           viewReplies: true,
                                                           animateScroll: false)
                }
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
        ConversationsManager.shared.activeController = controller
    }
    
    override func messageContent(_ content: MessageContentView,
                                 didTapMessage messageInfo: (ConversationId, MessageId)) {
        
        let message = Message.message(with: messageInfo.0, messageId: messageInfo.1)
        
        if let parentId = message.parentMessageId {
            self.presentThread(for: messageInfo.0, messageId: parentId, startingReplyId: messageInfo.1)
        } else {
            self.presentMessageDetail(for: messageInfo.0, messageId: messageInfo.1)
        }
    }
    
    override func messageContent(_ content: MessageContentView,
                                 didTapViewReplies messageInfo: (ConversationId, MessageId)) {
        
        self.presentThread(for: messageInfo.0, messageId: messageInfo.1, startingReplyId: nil)
    }
}

extension ConversationCoordinator: LaunchActivityHandler {
    func handle(launchActivity: LaunchActivity) {
        switch launchActivity {
        case .onboarding(let phoneNumber):
            logDebug("Launched with: \(phoneNumber)")
        case .reservation(let reservationId):
            logDebug("Launched with: \(reservationId)")
        case .pass(let passId):
            logDebug("Launched with: \(passId)")
        case .deepLink(let deepLinkable):
            logDebug("Launched with: \(deepLinkable)")
        }
    }
}
