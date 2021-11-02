//
//  ConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Photos
import PhotosUI
import Combine
import StreamChat

class ConversationCoordinator: PresentableCoordinator<Void> {

    lazy var conversationVC = ConversationViewController(conversation: ConversationsManager.shared.activeConversations.last, startingMessageId: nil)

    let startingMessageId: MessageId?

    init(router: Router,
         deepLink: DeepLinkable?,
         conversation: Conversation?,
         startingMessageId: MessageId?) {

        self.startingMessageId = startingMessageId
        
        if let convo = conversation {
            ConversationsManager.shared.activeConversations.append(convo)
        }
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        self.conversationVC.onSelectedThread = { [unowned self] (channelID, messageID) in
            self.presentThread(for: channelID, messageID: messageID)
        }
        return self.conversationVC
    }

    override func start() {
        super.start()

        self.conversationVC.didTapMoreButton = { [unowned self] in
            self.presentPeoplePicker()
        }

        self.conversationVC.didTapConversationTitle = { [unowned self] in
            guard let conversationController = self.conversationVC.conversationController,
            conversationController.conversation.membership?.memberRole.rawValue == "owner" else { return }
            self.presentConversationTitleAlert(for: conversationController)
        }
    }

    func presentPeoplePicker() {
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { [unowned self] connections in
            coordinator.toPresentable().dismiss(animated: true)
            guard let conversationController = self.conversationVC.conversationController else { return }
            self.add(connections: connections, to: conversationController)
        }
        self.router.present(coordinator, source: self.conversationVC)
    }

    func add(connections: [Connection], to controller: ChatChannelController) {
        let acceptedConnections = connections.filter { connection in
            return connection.status == .accepted
        }

        let pendingConnections = connections.filter { connection in
            return connection.status == .invited || connection.status == .pending
        }

        for connection in pendingConnections {
            let conversationID = controller.conversation.cid.id
            connection.initialConversations.append(conversationID)
            connection.saveEventually()
        }

        if !acceptedConnections.isEmpty {
            let members = acceptedConnections.compactMap { connection in
                return connection.nonMeUser?.objectId
            }
            controller.addMembers(userIds: Set(members)) { error in
                if error.isNil {
                    self.showPeopleAddedToast(for: acceptedConnections)
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
        }
    }

    func presentConversationTitleAlert(for controller: ChatChannelController) {
        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "New Name"
        }
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
                let text = textField.text,
                !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { [unowned self] error in
                    self.conversationVC.conversationHeader.layoutNow()
                    alertController.dismiss(animated: true, completion: {
                        self.conversationVC.becomeFirstResponder()
                    })
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            self.conversationVC.becomeFirstResponder()
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.conversationVC.present(alertController, animated: true, completion: nil)
    }

    func presentThread(for channelID: ChannelId, messageID: MessageId) {
        let threadVC = ConversationThreadViewController(channelID: channelID, messageID: messageID)
        threadVC.dismissHandlers.append { [unowned self] in
            self.conversationVC.becomeFirstResponder()
        }
        self.router.present(threadVC, source: self.conversationVC)
    }
}
