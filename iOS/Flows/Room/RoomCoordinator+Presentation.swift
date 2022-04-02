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
    
    func presentConversation(with cid: ConversationId?, messageId: MessageId?) {
        
        let coordinator = ConversationListCoordinator(router: self.router,
                                                      deepLink: self.deepLink,
                                                      conversationMembers: [],
                                                      startingConversationId: cid,
                                                      startingMessageId: messageId)
        self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (_) in
            self.router.popModule() 
        })
        
        self.router.push(coordinator, cancelHandler: nil, animated: true)
        Task.onMainActorAsync {
            guard let cid = cid else { return }
            await Task.sleep(seconds: 0.1)
            await coordinator.listVC.scrollToConversation(with: cid, messageId: messageId)
        }
    }
    
    func presentPeoplePicker() {
        
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] people in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                Task {
                    await self.roomVC.reloadPeople()
                }
            }
        }
        
        self.router.present(coordinator, source: self.roomVC)
    }
    
    func presentWallet() {
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
                self.presentConversation(with: result, messageId: nil)
            }
        }
        
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
        self.addChildAndStart(coordinator) { _ in }
        self.router.present(coordinator, source: self.roomVC)
    }
}
