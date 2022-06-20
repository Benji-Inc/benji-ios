//
//  HomeCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


class HomeCoordinator: PresentableCoordinator<Void>, DeepLinkHandler {

    lazy var homeVC = HomeViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.homeVC
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
        self.homeVC.conversationsVC.dataSource.messageContentDelegate = self
        self.homeVC.noticesVC.dataSource.messageContentDelegate = self
        
        self.homeVC.noticesVC.dataSource.didSelectRightOption = { [unowned self] notice in
            self.handleRightOption(with: notice)
        }
        
        self.homeVC.noticesVC.dataSource.didSelectRemoveOption = { [unowned self] notice in
            NoticeStore.shared.delete(notice: notice)
            self.homeVC.noticesVC.reloadNotices()
        }
        
        self.homeVC.noticesVC.dataSource.didSelectLeftOption = { [unowned self] notice in
            self.handleLeftOption(with: notice)
        }
        
        self.homeVC.shortcutVC.didSelectOption = { [unowned self] option in
            self.homeVC.state = .dismissShortcuts
            
            switch option {
            case .newMessage:
                break
            case .newPerson:
                self.presentPeoplePicker()
            case .newVibe:
                self.presentVibeCreator()
            }
        }
        
//        self.homeVC.conversationsVC.dataSource.didSelectAddConversation = { [unowned self] in
//            Task {
//                guard let conversation = try? await JibberChatClient.shared.createNewConversation() else { return }
//                self.presentConversation(with: conversation.cid.description, messageId: nil)
//            }
//        }
        
//        self.roomVC.dataSource.didSelectAddPerson = { [unowned self] in
//            self.presentPeoplePicker()
//        }
        
        self.homeVC.membersVC.$selectedItems.mainSink { [unowned self] items in
            guard let itemType = items.first else { return }
            switch itemType {
            case .memberId(let personId):
                Task {
                    guard let person = await PeopleStore.shared.getPerson(withPersonId: personId) else {
                        return
                    }
                    self.presentProfile(for: person)
                }
            case .add(let reservationId):
                self.presentPeoplePicker()
            }
        }.store(in: &self.cancellables)
        
        self.homeVC.conversationsVC.$selectedItems.mainSink { [unowned self] items in
            guard let itemType = items.first else { return }
            
            switch itemType {
            case .conversation(let conversationId):
                self.presentConversation(with: conversationId, messageId: nil)
            }
            
        }.store(in: &self.cancellables)
        
        self.homeVC.noticesVC.$selectedItems.mainSink { [unowned self] items in
            guard let itemType = items.first else { return }
            switch itemType {
            case .notice(let notice):
                switch notice.type {
                case .timeSensitiveMessage:
                    guard let conversationId = notice.attributes?["cid"] as? String,
                          let messageId = notice.attributes?["messageId"] as? String else { return }
                    
                    self.presentConversation(with: conversationId, messageId: messageId)
                    NoticeStore.shared.delete(notice: notice)
                    self.homeVC.noticesVC.reloadNotices()
                default:
                    break
                }
            }
        }.store(in: &self.cancellables)
    }
}

extension HomeCoordinator: LaunchActivityHandler {
    
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

extension HomeCoordinator: MessageContentDelegate {
    
    func messageContent(_ content: MessageContentView, didTapViewReplies message: Messageable) {
        self.presentConversation(with: message.conversationId, messageId: message.id, openReplies: true)
    }
    
    func messageContent(_ content: MessageContentView,
                        didTapAttachmentForMessage message: Messageable) {

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
