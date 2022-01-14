//
//  ConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import Combine
import StreamChat
import Localization
import Intents

class ConversationListCoordinator: PresentableCoordinator<Void>, ActiveConversationable {

    lazy var conversationListVC
    = ConversationListViewController(members: self.conversationMembers,
                                     startingConversationID: self.startingConversationID,
                                     startingMessageID: self.startMessageID)

    private let conversationMembers: [ConversationMember]
    private let startingConversationID: ConversationId?
    private let startMessageID: MessageId?

    override func toPresentable() -> DismissableVC {
        return self.conversationListVC
    }

    init(router: Router,
         deepLink: DeepLinkable?,
         conversationMembers: [ConversationMember],
         startingConversationId: ConversationId?,
         startingMessageId: MessageId?) {

        self.conversationMembers = conversationMembers
        self.startingConversationID = startingConversationId
        self.startMessageID = startingMessageId

        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        self.conversationListVC.onSelectedMessage = { [unowned self] (channelId, messageId, replyId) in
            self.presentThread(for: channelId,
                                  messageId: messageId,
                                  startingReplyId: replyId)
        }

        self.conversationListVC.headerVC.didTapAddPeople = { [unowned self] in
            self.presentPeoplePicker()
        }
        
        self.conversationListVC.headerVC.didTapUpdateProfilePicture = { [unowned self] in
            self.presentProfilePicture()
        }

        self.conversationListVC.headerVC.didTapUpdateTopic = { [unowned self] in
            guard let conversation = self.activeConversation else {
                logDebug("Unable to change topic because no conversation is selected.")
                return
            }
            guard conversation.isOwnedByMe else {
                logDebug("Unable to change topic because conversation is not owned by user.")
                return
            }
            self.presentConversationTitleAlert(for: conversation)
        }

        Task {
            await self.checkForPermissions()
        }
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            var cid: ConversationId?
            let messageID = deeplink.messageId
    
            if deeplink.conversationId.exists {
                cid = deeplink.conversationId

            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {
                guard let connection = ConnectionStore.shared.connections.first(where: { connection in
                    return connection.objectId == connectionId
                }), let identifier = connection.initialConversations.first else { break }

                cid = try? ChannelId.init(cid: identifier)
            }

            guard let cid = cid else { break }
            Task {
                await self.conversationListVC.scrollToConversation(with: cid, messageID: messageID)
            }.add(to: self.taskPool)

        default:
            break
        }
    }

    func presentThread(for channelId: ChannelId,
                       messageId: MessageId,
                       startingReplyId: MessageId?) {

        self.removeChild()
        
        let coordinator = ThreadCoordinator(with: channelId,
                                            messageId: messageId,
                                            startingReplyId: startingReplyId,
                                            router: self.router,
                                            deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { [unowned self] _ in
            self.router.dismiss(source: self.conversationListVC)
        }

        self.router.present(coordinator, source: self.conversationListVC)
    }
    
    func presentProfilePicture() {
        let vc = ModalPhotoViewController()
        
        /// Because of how the People are presented, we need to properly reset the KeyboardManager.
        vc.dismissHandlers.append { [unowned self] in
            KeyboardManager.shared.addKeyboardObservers(with: self.conversationListVC.inputAccessoryView)
            self.conversationListVC.becomeFirstResponder()
        }
        
        KeyboardManager.shared.reset()
        self.conversationListVC.resignFirstResponder()
        self.router.present(vc, source: self.conversationListVC)
    }

    func presentPeoplePicker() {
        guard let conversation = self.activeConversation else { return }

        self.removeChild()
        let coordinator = PeopleCoordinator(conversationID: conversation.cid,
                                            router: self.router,
                                            deepLink: self.deepLink)
        
        /// Because of how the People are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self] in
            KeyboardManager.shared.addKeyboardObservers(with: self.conversationListVC.inputAccessoryView)
            self.conversationListVC.becomeFirstResponder()
        }

        self.addChildAndStart(coordinator) { [unowned self] connections in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                KeyboardManager.shared.addKeyboardObservers(with: self.conversationListVC.inputAccessoryView)
                self.conversationListVC.becomeFirstResponder()
                self.add(connections: connections, to: conversation)
            }
        }
        
        /// We don't get a will disappear call on the list, so we have to call it here.
        KeyboardManager.shared.reset()
        self.conversationListVC.resignFirstResponder()
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
                        KeyboardManager.shared.addKeyboardObservers(with: self.conversationListVC.inputAccessoryView)
                        self.conversationListVC.becomeFirstResponder()
                    })
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            KeyboardManager.shared.addKeyboardObservers(with: self.conversationListVC.inputAccessoryView)
            self.conversationListVC.becomeFirstResponder()
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        KeyboardManager.shared.reset()
        self.conversationListVC.resignFirstResponder()

        self.conversationListVC.present(alertController, animated: true, completion: nil)
    }
}

private class ModalPhotoViewController: PhotoViewController {
    
    private let gradientView = BackgroundGradientView()
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        self.view.insertSubview(self.gradientView, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.gradientView.expandToSuperviewSize()
    }
}

// MARK: - Permissions

extension ConversationListCoordinator {

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
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        
        /// Because of how the Permissions are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self] in
            KeyboardManager.shared.addKeyboardObservers(with: self.conversationListVC.inputAccessoryView)
            self.conversationListVC.becomeFirstResponder()
        }
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: self.conversationListVC, animated: true)
        }
        
        KeyboardManager.shared.reset()
        self.conversationListVC.resignFirstResponder()
        self.router.present(coordinator, source: self.conversationListVC)
    }
}
