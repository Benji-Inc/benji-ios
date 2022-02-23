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

class ConversationListCoordinator: PresentableCoordinator<Void>, ActiveConversationable {

    lazy var conversationListVC
    = ConversationListViewController(members: self.conversationMembers,
                                     startingConversationID: self.startingConversationID,
                                     startingMessageID: self.startMessageID)

    private let conversationMembers: [ConversationMember]
    private let startingConversationID: ConversationId?
    private let startMessageID: MessageId?

    override func toPresentable() -> DismissableVC {
        return self.conversationListVC
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         conversationMembers: [ConversationMember],
         startingConversationId: ConversationId?,
         startingMessageId: MessageId?) {

        self.conversationMembers = conversationMembers
        self.startingConversationID = startingConversationId
        self.startMessageID = startingMessageId

        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        self.conversationListVC.onSelectedMessage = { [unowned self] (channelId, messageId, replyId) in
            self.presentThread(for: channelId,
                                  messageId: messageId,
                                  startingReplyId: replyId)
        }
        
        self.conversationListVC.headerVC.jibImageView.didSelect { [unowned self] in
            self.showWallet() 
        }

        self.conversationListVC.headerVC.didTapAddPeople = { [unowned self] in
            self.presentPeoplePicker()
        }
        
        self.conversationListVC.swipeInputDelegate.didTapAvatar = { [unowned self] in
            self.presentProfile(for: User.current()!)
        }
        
        self.conversationListVC.headerVC.membersVC.$selectedItems.mainSink { items in
            guard let first = items.first else { return }
            switch first {
            case .member(let member):
                self.presentProfile(for: member.displayable.value)
            default:
                break 
            }
        }.store(in: &self.cancellables)

        self.conversationListVC.headerVC.didTapUpdateTopic = { [unowned self] in
            guard let conversation = self.activeConversation else {
                logDebug("Unable to change topic because no conversation is selected.")
                return
            }

            self.presentConversationTitleAlert(for: conversation)
        }
        
        self.conversationListVC.dataSource.handleAddPeopleSelected = { [unowned self] in
            Task {
                try await self.createNewConversation()
                Task.onMainActor {
                    self.presentPeoplePicker()
                }
            }
        }
        
        self.conversationListVC.dataSource.handleInvestmentSelected = { [unowned self] in
            self.presentEmailAlert() 
        }

        Task {
            await self.checkForPermissions()
        }.add(to: self.taskPool)
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            let messageID = deeplink.messageId
            guard let cid = deeplink.conversationId else { break }
            Task {
                await self.conversationListVC.scrollToConversation(with: cid, messageID: messageID)
            }.add(to: self.taskPool)

        default:
            break
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
        ConversationsManager.shared.activeConversation = controller.conversation
    }
}
