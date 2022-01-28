//
//  ConversationListCoordinator+Presentation.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Localization

extension ConversationListCoordinator {
    
    func presentCircle() {
        guard let query = Circle.query() else { return }
        query.whereKey("owner", equalTo: User.current()!)
        query.getFirstObjectInBackground { [unowned self] object, error in
            if let circle = object as? Circle {
                let coordinator = CircleCoordinator(with: circle,
                                                    router: self.router,
                                                    deepLink: self.deepLink)
                self.present(coordinator)
            }
        }
    }

    func presentThread(for channelId: ChannelId,
                       messageId: MessageId,
                       startingReplyId: MessageId?) {
        
        let coordinator = ThreadCoordinator(with: channelId,
                                            messageId: messageId,
                                            startingReplyId: startingReplyId,
                                            router: self.router,
                                            deepLink: self.deepLink)
        self.present(coordinator)
    }
    
    func presentProfilePicture() {
        let vc = ModalPhotoViewController()
        
        // Because of how the People are presented, we need to properly reset the KeyboardManager.
        vc.dismissHandlers.append { [unowned self] in
            self.conversationListVC.becomeFirstResponder()
        }
        
        vc.onDidComplete = { _ in
            vc.dismiss(animated: true, completion: nil)
        }

        self.conversationListVC.resignFirstResponder()
        self.router.present(vc, source: self.conversationListVC)
    }

    func presentPeoplePicker() {
        guard let conversation = self.activeConversation else { return }
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        self.present(coordinator) { [unowned self] people in
            self.add(people: people, to: conversation)
        }
    }
    
    private func present<ChildResult>(_ coordinator: PresentableCoordinator<ChildResult>,
                                      finishedHandler: ((ChildResult) -> Void)? = nil) {
        self.removeChild()
        
        // Because of how the People are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self] in
            self.conversationListVC.becomeFirstResponder()
        }
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.conversationListVC.becomeFirstResponder()
                finishedHandler?(result)
            }
        }
        
        self.conversationListVC.resignFirstResponder()
        self.router.present(coordinator, source: self.conversationListVC)
    }
    
    func add(people: [Person], to conversation: Conversation) {
        let controller = ChatClient.shared.channelController(for: conversation.cid)

        let accepted = people.compactMap { person in
            return person.connection
        }.filter { connection in
            return connection.status == .accepted
        }

        if !accepted.isEmpty {
            let members = accepted.compactMap { connection in
                return connection.nonMeUser?.objectId
            }
            controller.addMembers(userIds: Set(members)) { error in
                if error.isNil {
                    self.showPeopleAddedToast(for: accepted)
                }
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

    func presentConversationTitleAlert(for conversation: Conversation) {
        let controller = ChatClient.shared.channelController(for: conversation.cid)

        let alertController = UIAlertController(title: "Update Topic", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Topic"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { [unowned self] error in
                    self.conversationListVC.headerVC.topicLabel.setText(text)
                    self.conversationListVC.headerVC.view.layoutNow()
                    alertController.dismiss(animated: true, completion: {
                        self.conversationListVC.becomeFirstResponder()
                    })
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            self.conversationListVC.becomeFirstResponder()
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.conversationListVC.resignFirstResponder()

        self.conversationListVC.present(alertController, animated: true, completion: nil)
    }
}
