//
//  CircleCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class RoomCoordinator: PresentableCoordinator<Void>, DeepLinkHandler {
    
    lazy var roomVC = RoomViewController()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.roomVC
    }
    
    override func start() {
        super.start()
        
        if let deepLink = self.deepLink {
            self.handle(deepLink: deepLink)
        }
        
        self.setupHandlers()
        
        Task {
            await self.checkForPermissions()
        }.add(to: self.taskPool)
    }
    
    func handle(deepLink: DeepLinkable) {
        self.deepLink = deepLink

        guard let target = deepLink.deepLinkTarget else { return }

        switch target {
        case .conversation, .thread:
            let messageID = deepLink.messageId
            guard let conversationId = deepLink.conversationId else { break }
            self.presentConversation(with: conversationId, messageId: messageID, openReplies: target == .thread)
        case .wallet:
            self.presentWallet()
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
    
    private func setupHandlers() {
        self.roomVC.dataSource.messageContentDelegate = self 
        
        self.roomVC.headerView.jibImageView.didSelect { [unowned self] in
            self.presentWallet()
        }
        
        self.roomVC.headerView.button.didSelect { [unowned self] in
            guard let user = User.current() else { return }
            self.presentProfile(for: user)
        }
        
        self.roomVC.dataSource.didSelectRightOption = { [unowned self] notice in
            self.handleRightOption(with: notice)
        }
        
        self.roomVC.dataSource.didSelectRemoveOption = { [unowned self] notice in
            NoticeStore.shared.delete(notice: notice)
            self.roomVC.reloadNotices()
        }
        
        self.roomVC.dataSource.didSelectLeftOption = { [unowned self] notice in
            self.handleLeftOption(with: notice)
        }
        
        self.roomVC.dataSource.didSelectAddConversation = { [unowned self] in
            Task {
                guard let conversation = try? await self.createNewConversation() else { return }
                self.presentConversation(with: conversation.cid.description, messageId: nil)
            }
        }
        
        self.roomVC.dataSource.didSelectAddPerson = { [unowned self] in
            self.presentPeoplePicker()
        }
    
        self.roomVC.$selectedItems.mainSink { [unowned self] items in
            guard let itemType = items.first else { return }
            switch itemType {
            case .memberId(let personId):
                Task {
                    guard let person = await PeopleStore.shared.getPerson(withPersonId: personId) else {
                        return
                    }
                    self.presentProfile(for: person)
                }
            case .conversation(let cid):
                self.presentConversation(with: cid.description, messageId: nil)
            case .unreadMessages(let model):
                self.presentConversation(with: model.cid.description, messageId: model.messageIds.first)
            case .add(_):
                self.presentPeoplePicker()
            case .notice(let notice):
                switch notice.type {
                case .timeSensitiveMessage:
                    guard let cidValue = notice.attributes?["cid"] as? String,
                          let cid = try? ChannelId(cid: cidValue),
                          let messageId = notice.attributes?["messageId"] as? String else { return }
                    
                    self.presentConversation(with: cid.description, messageId: messageId)
                    NoticeStore.shared.delete(notice: notice)
                    self.roomVC.reloadNotices()
                default:
                    break
                }
            default:
                break
            }
        }.store(in: &self.cancellables)
    }

    func createNewConversation() async throws -> Conversation? {
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
        return controller.conversation
    }
}

extension RoomCoordinator: LaunchActivityHandler {
    func handle(launchActivity: LaunchActivity) {
        switch launchActivity {
        case .onboarding(let phoneNumber):
            logDebug("Launched with: \(phoneNumber ?? "")")
        case .reservation(_), .pass(_):
            self.presentPersonConnection(for: launchActivity)
        case .deepLink(let deepLinkable):
            logDebug("Launched with: \(deepLinkable)")
        }
    }
}

extension RoomCoordinator: MessageContentDelegate {
    
    func messageContent(_ content: MessageContentView,
                        didTapViewReplies messageInfo: (ConversationId, MessageId)) {

        self.presentConversation(with: messageInfo.0.description, messageId: messageInfo.1, openReplies: true)
    }
    
    func messageContent(_ content: MessageContentView,
                        didTapMessage messageInfo: (ConversationId, MessageId)) {
        
    }
    
    func messageContent(_ content: MessageContentView,
                        didTapEditMessage messageInfo: (ConversationId, MessageId)) {
        
    }
    
    func messageContent(_ content: MessageContentView,
                        didTapAttachmentForMessage messageInfo: (ConversationId, MessageId)) {

        let message = Message.message(with: messageInfo.0, messageId: messageInfo.1)

        switch message.kind {
        case .photo(photo: let photo, _):
            self.presentMediaFlow(for: [photo], startingItem: nil, message: message)
        case .video(video: let video, _):
            self.presentMediaFlow(for: [video], startingItem: nil, message: message)
        case .media(items: let media, _):
            self.presentMediaFlow(for: media, startingItem: nil, message: message)
        case .text, .attributedText, .location, .emoji, .audio, .contact, .link:
            break
        }
    }
}
