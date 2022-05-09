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
    case message(ConversationId, MessageId)
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
        
        self.detailVC.dataSource.messageContentDelegate = self
        
        self.detailVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }
            
            switch first {
            case .pinnedMessage(let model):
                guard let cid = model.cid, let messageId = model.messageId else { return }
                self.finishFlow(with: .message(cid, messageId))
            case .member(let member):
                guard let person = PeopleStore.shared.people.first(where: { person in
                    return person.personId == member.personId
                }) else { return }

                self.presentProfile(for: person)
            case .info(_):
                break
            case .editTopic(let cid):
                self.presentConversationTitleAlert(for: cid)
            case .detail(let option):
                if option == .add {
                    self.presentPeoplePicker()
                } else {
                    self.presentDetail(option: option)
                }
            }
        }.store(in: &self.cancellables)
    }
    
    func presentProfile(for person: PersonType) {
        self.removeChild()

        let coordinator = ProfileCoordinator(with: person, router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                switch result {
                case .conversation(let cid):
                    self.finishFlow(with: .conversation(cid))
                case .openReplies(_, _):
                    break
                }
            }
        }
        
        self.router.present(coordinator, source: self.detailVC, cancelHandler: nil)
    }
    
    func presentConversationTitleAlert(for cid: ConversationId) {
        let controller = ChatClient.shared.channelController(for: cid)

        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
            textField.autocapitalizationType = .words
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

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentDetail(option: ConversationDetailCollectionViewDataSource.OptionType) {
        let controller = ChatClient.shared.channelController(for: self.cid)
        
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
        case .add:
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let primaryAction = UIAlertAction(title: title, style: style, handler: {
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
            case .add:
                return 
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(primaryAction)
        alertController.addAction(cancelAction)
        
        self.detailVC.present(alertController, animated: true, completion: nil)
    }
    
    func presentPeoplePicker() {
        guard let conversation = ConversationController.controller(self.cid).conversation else { return }

        self.removeChild()

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

extension ConversationDetailCoordinator: MessageContentDelegate {
    
    func messageContent(_ content: MessageContentView, didTapViewReplies messageInfo: (ConversationId, MessageId)) {
        
    }
    
    func messageContent(_ content: MessageContentView, didTapMessage messageInfo: (ConversationId, MessageId)) {
        self.finishFlow(with: .message(messageInfo.0, messageInfo.1))
    }
    
    func messageContent(_ content: MessageContentView, didTapEditMessage messageInfo: (ConversationId, MessageId)) {
        
    }
    
    func messageContent(_ content: MessageContentView, didTapAttachmentForMessage messageInfo: (ConversationId, MessageId)) {
        let message = Message.message(with: messageInfo.0, messageId: messageInfo.1)

        switch message.kind {
        case .photo(photo: let photo, let body):
            let text = "\(message.author.givenName): \(body)"
            self.presentMediaFlow(for: [photo], startingItem: nil, body: text)
        case .video(video: let video, body: let body):
            let text = "\(message.author.givenName): \(body)"
            self.presentMediaFlow(for: [video], startingItem: nil, body: text)
        case .media(items: let media, body: let body):
            let text = "\(message.author.givenName): \(body)"
            self.presentMediaFlow(for: media, startingItem: nil, body: text)
        case .text, .attributedText, .location, .emoji, .audio, .contact, .link:
            break
        }
    }
    
    func presentMediaFlow(for mediaItems: [MediaItem], startingItem: MediaItem?, body: String) {
        self.removeChild()
        let coordinator = MediaViewerCoordinator(items: mediaItems,
                                                 startingItem: startingItem,
                                                 body: body,
                                                 router: self.router,
                                                 deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { _ in }
        self.router.present(coordinator, source: self.detailVC, cancelHandler: nil)
    }
}
