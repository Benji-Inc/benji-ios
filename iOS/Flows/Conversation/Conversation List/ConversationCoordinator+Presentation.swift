//
//  ConversationCoordinator+Presentation.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Localization
import Photos

extension ConversationCoordinator {
        
    func presentThread(for cid: ConversationId,
                       messageId: MessageId,
                       startingReplyId: MessageId?) {
        
        let coordinator = ThreadCoordinator(with: cid,
                                            messageId: messageId,
                                            startingReplyId: startingReplyId,
                                            router: self.router,
                                            deepLink: self.deepLink)
        
        self.present(coordinator) { [unowned self] result in
            Task.onMainActorAsync {
                await self.listVC.scrollToConversation(with: result, messageId: nil, animateScroll: false)
            }
        }
    }
    
    func presentMessageDetail(for channelId: ChannelId, messageId: MessageId) {
        let message = Message.message(with: channelId, messageId: messageId)
        let coordinator = MessageDetailCoordinator(with: message,
                                                   router: self.router,
                                                   deepLink: self.deepLink)
        
        self.present(coordinator) { [unowned self] result in
            switch result {
            case .message(_):
                self.presentThread(for: channelId,
                                   messageId: messageId,
                                   startingReplyId: nil)
            case .reply(let replyId):
                self.presentThread(for: channelId,
                                   messageId: messageId,
                                   startingReplyId: replyId)
            case .conversation(let conversation):
                Task.onMainActorAsync {
                    await self.listVC.scrollToConversation(with: conversation, messageId: nil, animateScroll: false)
                }
            case .none:
                break
            }
        }
    }
    
    func presentPeoplePicker() {
        // If there is no conversation to invite people to, then do nothing.
        guard let conversation = self.activeConversation else { return }
        
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        coordinator.selectedConversationCID = self.activeConversation?.cid
        
        self.present(coordinator, finishedHandler: { [unowned self] invitedPeople in
            self.handleInviteFlowEnded(givenInvitedPeople: invitedPeople, activeConversation: conversation)
        }, cancelHandler: { [unowned self, unowned coordinator = coordinator] in
            let invitedPeople = coordinator.invitedPeople
            self.handleInviteFlowEnded(givenInvitedPeople: invitedPeople, activeConversation: conversation)
        })
    }
    
    private func handleInviteFlowEnded(givenInvitedPeople invitedPeople: [Person],
                                       activeConversation: Conversation) {
        
        if invitedPeople.isEmpty {
            // If the user didn't invite anyone to the conversation and the conversation doesn't have
            // any existing members, ask them if they'd like to delete it.
            Task {
                let peopleInConversation = await PeopleStore.shared.getPeople(for: activeConversation)
                guard peopleInConversation.isEmpty else { return }
                
                self.presentDeleteConversationAlert(cid: activeConversation.cid)
            }
        } else {
            // Add all of the invited people to the conversation.
            self.add(people: invitedPeople, to: activeConversation)
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
    
    func presentDeleteConversationAlert(cid: ConversationId?) {
        guard let cid = cid else { return }
                
        let controller = ChatClient.shared.channelController(for: cid)
        guard let conversation = controller.conversation, conversation.memberCount <= 1 else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete Conversation", style: .destructive, handler: {
            (action : UIAlertAction!) -> Void in
            Task {
                try await controller.deleteChannel()
            }
            self.listVC.becomeFirstResponder()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            self.listVC.becomeFirstResponder()
        })
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.listVC.resignFirstResponder()
        self.listVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentEmailAlert() {
        let alertController = UIAlertController(title: "Invest in Jibber",
                                                message: "We will follow up with you using the email provided.",
                                                preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.textContentType = .emailAddress
            textField.placeholder = "Email"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {
                
                Task {
                    User.current()?.email = text
                    try await User.current()?.saveToServer()
                    
                    Task.onMainActor {
                        alertController.dismiss(animated: true, completion: {
                            self.listVC.dataSource.reloadItems([.invest])
                            self.listVC.becomeFirstResponder()
                        })
                    }
                }
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            self.listVC.becomeFirstResponder()
        })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.listVC.resignFirstResponder()
        
        self.listVC.present(alertController, animated: true, completion: nil)
    }
    
    func showWallet() {
        let coordinator = WalletCoordinator(router: self.router, deepLink: self.deepLink)
        self.present(coordinator, finishedHandler: nil)
    }
    
    func presentConversationDetail() {
        guard let cid = self.activeConversation?.cid else { return }
        
        let coordinator = ConversationDetailCoordinator(with: cid,
                                                        router: self.router,
                                                        deepLink: self.deepLink)
        self.present(coordinator) { [unowned self] result in
            guard let option = result else { return }
            
            switch option {
            case .conversation(let cid):
                Task.onMainActorAsync {
                    await self.listVC.scrollToConversation(with: cid, messageId: nil, animateScroll: false)
                }
            case .message(let cid, let messageId):
                Task.onMainActorAsync {
                    await self.listVC.scrollToConversation(with: cid, messageId: messageId, animateScroll: true)
                }
            }
        }
    }
}
