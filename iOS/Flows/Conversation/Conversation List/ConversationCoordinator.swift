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
import Coordinator

/// A coordinator for displaying a single conversation.
class ConversationCoordinator: InputHandlerCoordinator<Void>, DeepLinkHandler {
    
    var conversationVC: ConversationViewController {
        return self.inputHandlerViewController as! ConversationViewController
    }
    
    init(router: CoordinatorRouter,
         deepLink: DeepLinkable?,
         conversationId: String,
         startingMessageId: String?,
         openReplies: Bool = false) {
        
        let vc = ConversationViewController(conversationId: conversationId,
                                            startingMessageId: startingMessageId,
                                            openReplies: openReplies)
        
        super.init(with: vc, router: router, deepLink: deepLink)
    }
    
    override func start() {
        super.start()
        
        self.conversationVC.headerVC.closeButton.didSelect { [unowned self] in
            self.finishFlow(with: ())
        }
        
        self.conversationVC.headerVC.button.didSelect { [unowned self] in
            self.presentConversationDetail()
        }
        
        self.conversationVC.dataSource.handleAddPeopleSelected = { [unowned self] in
            self.presentPeoplePicker()
        }
    }
    
    func handle(deepLink: DeepLinkable) {
        self.deepLink = deepLink
        
        guard let target = deepLink.deepLinkTarget else { return }
        
        switch target {
        case .conversation:
            let messageID = deepLink.messageId
            guard let value = deepLink.conversationId, let cid = try? ChannelId(cid: value) else { break }
            Task {
                await self.conversationVC.scrollToConversation(with: cid,
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
                    await self.conversationVC.scrollToConversation(with: cid, messageId: nil, animateScroll: false)
                }
            case .openReplies(let cid, let messageId):
                Task.onMainActorAsync {
                    await self.conversationVC.scrollToConversation(with: cid,
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
    
    override func presentThread(for cid: ConversationId,
                       messageId: MessageId,
                       startingReplyId: MessageId?) {
        
        let coordinator = ThreadCoordinator(with: cid,
                                            messageId: messageId,
                                            startingReplyId: startingReplyId,
                                            router: self.router,
                                            deepLink: self.deepLink)
        
        self.present(coordinator) { [unowned self] result in
            Task.onMainActorAsync {
                await self.conversationVC.scrollToConversation(with: result, messageId: nil, animateScroll: false)
            }
        }
    }
}

extension ConversationCoordinator: LaunchActivityHandler {
    func handle(launchActivity: LaunchActivity) {
        switch launchActivity {
        case .onboarding(let phoneNumber):
            logDebug("Launched with: \(phoneNumber)")
        case .reservation(_), .pass(_):
            self.presentPersonConnection(for: launchActivity)
        case .deepLink(let deepLinkable):
            logDebug("Launched with: \(deepLinkable)")
        }
    }
}
