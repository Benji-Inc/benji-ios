//
//  HomeCoordinator+Presentation.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

extension HomeCoordinator {
    
    func presentConversation(with conversationId: String?,
                             messageId: String?,
                             openReplies: Bool = false) {
        
        let coordinator = ConversationCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  conversationId: conversationId,
                                                  startingMessageId: messageId,
                                                  openReplies: openReplies)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            coordinator.toPresentable().dismiss(animated: true) {
                self.homeVC.conversationsVC.collectionView.visibleCells.forEach { cell in
                    if let c = cell as? ConversationCell {
                        c.content.messageContent.authorView.expressionVideoView.shouldPlay = true
                    }
                }
            }
        })
        
        self.router.present(coordinator, source: self.homeVC)
    }
    
    func presentMediaFlow(for mediaItems: [MediaItem],
                          startingItem: MediaItem?,
                          message: Messageable) {
        
        let coordinator = MediaCoordinator(items: mediaItems,
                                           startingItem: startingItem,
                                           message: message,
                                           router: self.router,
                                           deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator, finishedHandler: { [unowned self] result in
            switch result {
            case .reply(let message):
                coordinator.toPresentable().dismiss(animated: true) {
                    self.presentConversation(with: message.conversationId, messageId: message.id)
                }
            case .none:
                coordinator.toPresentable().dismiss(animated: true)
            }
        })
        
        self.router.present(coordinator, source: self.homeVC)
    }
    
    func presentVibeCreator() {
        self.removeChild()

        let coordinator = ContextCueCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { _ in
            coordinator.toPresentable().dismiss(animated: true, completion: nil)
        }

        self.router.present(coordinator, source: self.homeVC)
    }
    
    func presentPeoplePicker() {
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] people in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.homeVC.membersVC.reloadPeople()
            }
        }
        
        self.router.present(coordinator, source: self.homeVC)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                switch result {
                case .conversation(let cid):
                    self.presentConversation(with: cid.description, messageId: nil)
                case .openReplies(let message):
                    self.presentConversation(with: message.conversationId,
                                             messageId: message.id,
                                             openReplies: false)
                }
            }
        }
        
        self.router.present(coordinator, source: self.homeVC, cancelHandler: nil)
    }
    
    func presentPersonConnection(for activity: LaunchActivity) {
        self.removeChild()

        let coordinator = PersonConnectionCoordinator(launchActivity: activity,
                                                      router: self.router,
                                                      deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true)
        }

        self.router.present(coordinator, source: self.homeVC, cancelHandler: nil)
    }
}

// MARK: - Permissions Flow

extension HomeCoordinator {

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
        self.removeChild()
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] _ in
            self.homeVC.dismiss(animated: true)
        }
        self.router.present(coordinator, source: self.homeVC)
    }
}
