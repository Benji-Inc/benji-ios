//
//  CircleCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class RoomCoordinator: PresentableCoordinator<Void> {
    
    lazy var roomVC = RoomViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.roomVC
    }
    
    override func start() {
        super.start()
        
        if let deepLink = self.deepLink {
            self.handle(deeplink: deepLink)
        }
        
        self.setupHandlers()
        
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
            self.presentConversation(with: cid, messageId: messageID)
        case .wallet:
            self.presentWallet()
        default:
            break
        }
    }
    
    private func setupHandlers() {
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
        
        self.roomVC.dataSource.didSelectLeftOption = { [unowned self] notice in
            self.handleLeftOption(with: notice)
        }
        
        self.roomVC.dataSource.didSelectAddConversation = { [unowned self] in
            Task {
                guard let conversation = try? await self.createNewConversation() else { return }
                self.presentConversation(with: conversation.cid, messageId: nil)
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
                    guard let person = await PeopleStore.shared.getPerson(withPersonId: personId) else { return }
                    self.presentProfile(for: person)
                }
            case .conversation(let cid):
                self.presentConversation(with: cid, messageId: nil)
            case .unreadMessages(let model):
                self.presentConversation(with: model.cid, messageId: model.messageIds.first)
            case .notice(_):
                break
            case .add(_):
                self.presentPeoplePicker()
            }
        }.store(in: &self.cancellables)
    }
    
    func createNewConversation() async throws -> Conversation {
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
