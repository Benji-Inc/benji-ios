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
import Lightbox

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
    }

    override func start() {
        super.start()
        
        self.listVC.onSelectedMessage = { [unowned self] (channelId, messageId, replyId) in
            if let replyId = replyId {
                self.presentThread(for: channelId, messageId: messageId, startingReplyId: replyId)
            } else {
                self.presentMessageDetail(for: channelId, messageId: messageId)
            }
        }
        
        self.listVC.headerVC.jibImageView.didSelect { [unowned self] in
            self.showWallet() 
        }

        self.listVC.swipeInputDelegate.didTapAvatar = { [unowned self] in
            self.presentProfile(for: User.current()!)
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
                await self.listVC.scrollToConversation(with: cid, messageID: messageID)
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

// MARK: - Permissions Flow

extension ConversationListCoordinator {

    @MainActor
    func checkForPermissions() async {
        if INFocusStatusCenter.default.authorizationStatus != .authorized {
            self.presentPermissions()
        } else if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            self.presentPermissions()
        }
    }

    @MainActor
    private func presentPermissions() {
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        self.present(coordinator, finishedHandler: nil, cancelHandler: nil)
    }
}

// MARK: - Image View Flow

extension ConversationListCoordinator: LightboxControllerDismissalDelegate {

    func presentImageFlow(for imageURL: URL) {
        let images = [LightboxImage(imageURL: imageURL)]

        // Create an instance of LightboxController.
        let controller = LightboxController(images: images)

        // Set delegates.
        controller.dismissalDelegate = self

        // Use dynamic background.
        controller.dynamicBackground = true

        self.listVC.present(controller, animated: true)
    }

    nonisolated func lightboxControllerWillDismiss(_ controller: LightboxController) {

    }
}
