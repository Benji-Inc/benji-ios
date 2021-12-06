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

class ConversationListCoordinator: PresentableCoordinator<Void>, ActiveConversationable {

    lazy var conversationListVC
    = ConversationListViewController(members: self.conversationMembers,
                                     startingConversationID: self.startingConversationID)

    private let conversationMembers: [ConversationMember]
    private let startingConversationID: ConversationID?

    override func toPresentable() -> DismissableVC {
        return self.conversationListVC
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         conversationMembers: [ConversationMember],
         startingConversationID: ConversationID?) {

        self.conversationMembers = conversationMembers
        self.startingConversationID = startingConversationID

        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        self.conversationListVC.onSelectedMessage = { [unowned self] (channelId, messageId) in
            self.presentThread(for: channelId, messageId: messageId)
        }

        self.conversationListVC.headerVC.didTapAddPeople = { [unowned self] in
            self.presentPeoplePicker()
        }

        self.conversationListVC.headerVC.didTapUpdateTopic = { [unowned self] in
            guard let conversation = self.activeConversation else {
                logDebug("Unable to change topic because no conversation is selected.")
                return
            }
            guard conversation.membership?.memberRole.rawValue == "owner" else {
                logDebug("Unable to change topic because conversation is not owned by user.")
                return
            }
            self.presentConversationTitleAlert(for: conversation)
        }
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            if let identifier = deeplink.customMetadata["conversationId"] as? String {
                guard let conversationId = try? ChannelId.init(cid: identifier) else { return }
                let conversation = ChatClient.shared.channelController(for: conversationId).conversation
                let messageId = deeplink.customMetadata["messageId"] as? String
                //self.startConversationFlow(for: conversation, startingMessageId: messageId)
            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {

                guard let connection = ConnectionStore.shared.connections.first(where: { connection in
                    return connection.objectId == connectionId
                }), let identifier = connection.initialConversations.first,
                       let conversationId = try? ChannelId.init(cid: identifier)  else {
                           return
                       }
                let conversation = ChatClient.shared.channelController(for: conversationId).conversation

               // self.startConversationFlow(for: conversation, startingMessageId: nil)
            }

        default:
            break
        }
    }

    func presentThread(for channelId: ChannelId, messageId: MessageId) {
        self.removeChild()
        let coordinator = ThreadCoordinator(with: channelId,
                                            messageId: messageId,
                                            router: self.router,
                                            deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { _ in
            self.router.dismiss(source: coordinator.toPresentable())
        }

        self.router.present(coordinator, source: self.conversationListVC)
    }

    func presentPeoplePicker() {
        guard let conversation = self.activeConversation else { return }

        self.removeChild()
        let coordinator = PeopleCoordinator(conversationId: conversation.conversationId,
                                            router: self.router,
                                            deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { [unowned self] connections in
            self.router.dismiss(source: coordinator.toPresentable(), animated: false) {
                self.conversationListVC.becomeFirstResponder()
            }

            self.add(connections: connections, to: conversation)
        }
        self.router.present(coordinator, source: self.conversationListVC)
    }

    func add(connections: [Connection], to conversation: Conversation) {
        let controller = ChatClient.shared.channelController(for: conversation.cid)

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

    func presentConversationTitleAlert(for conversation: Conversation) {
        let controller = ChatClient.shared.channelController(for: conversation.cid)

        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "New Name"
        }
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { [unowned self] error in
                    self.conversationListVC.view.layoutNow()
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

        self.conversationListVC.present(alertController, animated: true, completion: nil)
    }
}
