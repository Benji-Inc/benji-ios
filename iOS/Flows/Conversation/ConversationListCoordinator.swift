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

        self.conversationListVC.headerVC.didTapAddPeople = { [unowned self] in
            self.presentPeoplePicker()
        }
        
        self.conversationListVC.swipeInputDelegate.didTapAvatar = { [unowned self] in
            self.presentProfilePicture()
        }

        self.conversationListVC.headerVC.didTapUpdateTopic = { [unowned self] in
            guard let conversation = self.activeConversation else {
                logDebug("Unable to change topic because no conversation is selected.")
                return
            }
            guard conversation.isOwnedByMe else {
                logDebug("Unable to change topic because conversation is not owned by user.")
                return
            }
            self.presentConversationTitleAlert(for: conversation)
        }
        
        self.conversationListVC.dataSource.handleCreateGroupSelected = { [unowned self] in
            self.presentCircle()
        }

        Task {
            await self.checkForPermissions()
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
                await self.conversationListVC.scrollToConversation(with: cid, messageID: messageID)
            }.add(to: self.taskPool)

        default:
            break
        }
    }
}
