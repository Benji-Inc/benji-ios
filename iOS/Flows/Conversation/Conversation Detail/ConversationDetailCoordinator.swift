//
//  ConversationDetailCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat
import Localization

enum DetailCoordinatorResult {
    case conversation(ConversationId)
}

class ConversationDetailCoordinator: PresentableCoordinator<DetailCoordinatorResult?> {
    
    lazy var detailVC = ConversationDetailViewController(with: self.cid)
    let cid: ConversationId
    
    init(with cid: ConversationId,
         router: Router,
         deepLink: DeepLinkable?) {
        self.cid = cid 
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.detailVC
    }
    
    override func start() {
        super.start()
        
        self.detailVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            
            switch first {
            case .member(let member):
                guard let person = PeopleStore.shared.people.first(where: { person in
                    return person.personId == member.personId
                }) else { return }

                self.presentProfile(for: person)
            case .add(_):
                self.presentPeoplePicker()
            case .info(_):
                break
            case .editTopic(let cid):
                self.presentConversationTitleAlert(for: cid)
            case .detail(let cid, let option):
                self.presentDetail(option: option, cid: cid)
            }
        }.store(in: &self.cancellables)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.finishFlow(with: .conversation(result))
            }
        }
        
        self.router.present(coordinator, source: self.detailVC, cancelHandler: nil)
    }
    
    func presentConversationTitleAlert(for cid: ConversationId) {
        let controller = ChatClient.shared.channelController(for: cid)

        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { _ in
                    alertController.dismiss(animated: true, completion: {
                    })
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentDetail(option: ConversationDetailCollectionViewDataSource.OptionType, cid: ConversationId) {
                
        let controller = ChatClient.shared.channelController(for: cid)
        
        var title: String = ""
        var message: String = ""
        var style: UIAlertAction.Style = .default
        
        switch option {
        case .hide:
            title = "Hide"
            message = "Hiding this conversation will archive the conversation until a new message is sent to it."
        case .leave:
            title = "Leave"
            message = "Leaving the conversation will remove you as a participant."
        case .delete:
            title = "Delete"
            message = "Deleting a conversation will remove all members and data associated with this conversation."
            style = .destructive
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let primaryAction = UIAlertAction(title: "Confirm", style: style, handler: {
            (action : UIAlertAction!) -> Void in
            
            switch option {
            case .hide:
                Task {
                    try? await controller.hideChannel(clearHistory: false)
                    Task.onMainActor {
                        self.finishFlow(with: nil)
                    }
                }.add(to: self.taskPool)
            case .leave:
                Task {
                    let user = User.current()!.objectId!
                    try? await controller.removeMembers(userIds: Set.init([user]))
                    Task.onMainActor {
                        self.finishFlow(with: nil)
                    }
                }.add(to: self.taskPool)
            case .delete:
                Task {
                    try? await controller.deleteChannel()
                    Task.onMainActor {
                        self.finishFlow(with: nil)
                    }
                }.add(to: self.taskPool)
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })

        alertController.addAction(primaryAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentPeoplePicker() {
        
        self.removeChild()

        let conversation = ConversationController.controller(self.cid).conversation

        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        coordinator.selectedConversationCID = self.cid
        
        // Because of how the People are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self, unowned cor = coordinator] in
            let invitedPeople = cor.invitedPeople
            self.handleInviteFlowEnded(givenInvitedPeople: invitedPeople, activeConversation: conversation)
        }
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true)
        }
        
        self.router.present(coordinator, source: self.detailVC)
    }
    
    private func handleInviteFlowEnded(givenInvitedPeople invitedPeople: [Person],
                                                       activeConversation: Conversation) {

        if !invitedPeople.isEmpty {
            self.add(people: invitedPeople, to: activeConversation)
            Task {
                await self.detailVC.reloadPeople(with: invitedPeople)
            }
        } 
    }
    
    func add(people: [Person], to conversation: Conversation) {
        let controller = ChatClient.shared.channelController(for: conversation.cid)

        let acceptedConnections = people.compactMap { person in
            return person.connection
        }.filter { connection in
            return connection.status == .accepted
        }

        guard !acceptedConnections.isEmpty else { return }

        let members = acceptedConnections.compactMap { connection in
            return connection.nonMeUser?.objectId
        }
        controller.addMembers(userIds: Set(members)) { error in
            guard error.isNil else { return }

            self.showPeopleAddedToast(for: acceptedConnections)
            Task {
                try await controller.synchronize()
            }
        }
    }
    
    private func showPeopleAddedToast(for connections: [Connection]) {
        Task {
            if connections.count == 1, let first = connections.first?.nonMeUser {
                let text = LocalizedString(id: "", arguments: [first.fullName], default: "@(name) has been added to the conversation.")
                await ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: first, title: "\(first.givenName.capitalized) Added", description: text, deepLink: nil))
            } else {
                let text = LocalizedString(id: "", arguments: [String(connections.count)], default: " @(count) people have been added to the conversation.")
                await ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: User.current()!, title: "\(String(connections.count)) Added", description: text, deepLink: nil))
            }
        }.add(to: self.taskPool)
    }
}
