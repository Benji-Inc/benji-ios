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
    
    lazy var pickerVC: PHPickerViewController = {
        var filter = PHPickerFilter.any(of: [.images])
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = filter
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        return vc
    }()

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
            if let replyId = replyId {
                self.presentThread(for: channelId, messageId: messageId, startingReplyId: replyId)
            } else {
                self.presentMessageDetail(for: channelId, messageId: messageId)
            }
        }
        
        self.conversationListVC.headerVC.jibImageView.didSelect { [unowned self] in
            self.showWallet() 
        }
        
        self.conversationListVC.swipeInputDelegate.didTapAvatar = { [unowned self] in
            self.presentProfile(for: User.current()!)
        }
        
        self.conversationListVC.messageInputController.swipeInputView.addView.didSelect { [unowned self] in
            self.presentAttachements()
        }
        
        self.conversationListVC.headerVC.button.didSelect { [unowned self] in
            self.presentConversationDetail()
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
        case .wallet:
            self.showWallet()
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
        AnalyticsManager.shared.trackEvent(type: .conversationCreated, properties: nil)
        ConversationsManager.shared.activeConversation = controller.conversation
    }
}
