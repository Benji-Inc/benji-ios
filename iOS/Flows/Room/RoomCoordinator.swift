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
        
        self.roomVC.headerView.jibImageView.didSelect { [unowned self] in
            self.presentWallet()
        }
        
        self.roomVC.headerView.button.didSelect { [unowned self] in
            guard let user = User.current() else { return }
            self.presentProfile(for: user)
        }
    
        self.roomVC.$selectedItems.mainSink { [unowned self] items in
            guard let itemType = items.first else { return }
            switch itemType {
            case .memberId(let personId):
                Task {
                    guard let person = await PeopleStore.shared.getPerson(withPersonId: personId) else { return }
                    self.presentProfile(for: person)
                }
            case .conversation(_):
                 break
            case .notice(_):
                break
            case .add(_):
                Task {
                    try await self.createNewConversation()
                    Task.onMainActor {
                        self.presentPeoplePicker()
                    }
                }
            }
        }.store(in: &self.cancellables)
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
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                //self.finishFlow(with: .conversation(result))
            }
        }
        
        self.router.present(coordinator, source: self.roomVC, cancelHandler: nil)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                //self.finishFlow(with: .conversation(result))
            }
        }
        
        self.router.present(coordinator, source: self.roomVC, cancelHandler: nil)
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
        //ConversationsManager.shared.activeConversation = controller.conversation
    }
}
