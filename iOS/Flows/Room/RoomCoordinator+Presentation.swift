//
//  RoomCoordinator+Presentation.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Intents

extension RoomCoordinator {
    
    func presentConversation(with cid: ConversationId?,
                             messageId: MessageId?,
                             openReplies: Bool = false) {
        
        let coordinator = ConversationListCoordinator(router: self.router,
                                                      deepLink: self.deepLink,
                                                      conversationMembers: [],
                                                      startingConversationId: cid,
                                                      startingMessageId: messageId,
                                                      openReplies: openReplies)
        self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (_) in
            self.router.popModule() 
        })
        
        self.router.push(coordinator, cancelHandler: nil, animated: true)
    }
    
    func presentPeoplePicker() {
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] people in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.roomVC.reloadPeople()
            }
        }
        
        self.router.present(coordinator, source: self.roomVC)
    }
    
    func presentWallet() {
        self.removeChild()
        
        let coordinator = WalletCoordinator(router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) 
        }
        
        self.router.present(coordinator, source: self.roomVC, cancelHandler: nil)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                switch result {
                case .conversation(let cid):
                    self.presentConversation(with: cid, messageId: nil)
                case .openReplies(let cid, let messageId):
                    self.presentConversation(with: cid,
                                             messageId: messageId,
                                             openReplies: false)
                }
            }
        }
        
        self.router.present(coordinator, source: self.roomVC, cancelHandler: nil)
    }
    
    func presentImageFlow(for imageURLs: [URL], startingURL: URL?, body: String) {
        self.removeChild()
        
        let coordinator = ImageViewCoordinator(imageURLs: imageURLs,
                                               startURL: startingURL,
                                               body: body,
                                               router: self.router,
                                               deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { _ in }
        self.router.present(coordinator, source: self.roomVC, cancelHandler: nil)
    }
}

// MARK: - Permissions Flow

extension RoomCoordinator {

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
            self.roomVC.dismiss(animated: true)
        }
        self.router.present(coordinator, source: self.roomVC)
    }
}
