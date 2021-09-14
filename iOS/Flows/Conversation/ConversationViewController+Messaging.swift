//
//  ConversationViewController+Messaging.swift
//  Benji
//
//  Created by Benji Dodgson on 6/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Photos
import StreamChat

extension ConversationViewController: SwipeableInputAccessoryViewDelegate {

    func handle(attachment: Attachment, body: String) {
        Task {
            do {
                let kind = try await AttachmentsManager.shared.getMessageKind(for: attachment, body: body)
                let object = SendableObject(kind: kind, context: .passive)
                await self.send(object: object)
            } catch {
                logDebug(error)
            }
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        if sendable.previousMessage.isNil {
            Task {
                await self.send(object: sendable)
            }
        } else {
            self.update(object: sendable)
        }
    }

    func load(activeConversation: DisplayableConversation) {
        switch activeConversation.conversationType {
        case .system(_):
            break
        case .conversation:
            self.loadMessages(for: activeConversation.conversationType)
        }
    }

    @MainActor
    func send(object: Sendable) async {
        guard let conversation = self.conversation else { return }

        switch conversation.conversationType {
        case .system(let conversation):
            return
        case .conversation(let channel):
            do {
                if case .text(let body) = object.kind {
                    let controller = chatClient.channelController(for: channel.cid)
                    try await controller.createNewMessage(text: body)

                    self.conversationCollectionView.scrollToEnd()
                }
            } catch {
                logDebug(error)
            }

        }
    }

    func resend(message: Messageable) async {
//        do {
//            let systemMessage = try await MessageDeliveryManager.shared.resend(message: message,
//                                                                               systemMessageHandler: { systemMessage in
//                self.collectionViewManager.updateItemSync(with: systemMessage)
//            })
//
//            if systemMessage.status == .error {
//                self.collectionViewManager.updateItemSync(with: systemMessage)
//            }
//        } catch {
//            logDebug(error)
//        }
    }

    func update(object: Sendable) {
//        if let updatedMessage = MessageSupplier.shared.update(object: object) {
//            self.indexPathForEditing = nil
//            self.collectionViewManager.updateItemSync(with: updatedMessage)
//            self.messageInputAccessoryView.reset()
//        }
    }

    private func showAlertSentToast(for message: SystemMessage) async {
//        guard let displaybleConversation = self.activeConversation,
//              case ConversationType.conversation(let conversation) = displaybleConversation.conversationType else { return }
//
//        var displayable: ImageDisplayable = User.current()!
//
//        guard let users = try? await conversation.getUsers(excludeMe: true) else {
//            return
//        }
//
//        var name: String = ""
//
//        if let friendlyName = conversation.friendlyName {
//            name = friendlyName
//        } else if users.count == 0 {
//            name = "You"
//        } else if users.count == 1, let user = users.first(where: { user in
//            return user.objectId != User.current()?.objectId
//        }) {
//            displayable = user
//            name = user.fullName
//        } else {
//            displayable = users.first!
//            name = self.displayGroupChat(for: conversation, with: users)
//        }
//
//        let description = "A notification linking to your message has been sent to: \(name)."
//        ToastScheduler.shared.schedule(toastType: .basic(identifier: message.id,
//                                                         displayable: displayable,
//                                                         title: "Notification Sent",
//                                                         description: description,
//                                                         deepLink: nil))
    }

//    private func displayGroupChat(for conversation: TCHChannel, with users: [User]) -> String {
//        var text = ""
//        for (index, user) in users.enumerated() {
//            if index < users.count - 1 {
//                text.append(String("\(user.givenName), "))
//            } else if index == users.count - 1 && users.count > 1 {
//                text.append(String("\(user.givenName)"))
//            } else {
//                text.append(user.givenName)
//            }
//        }
//
//        return text
//    }
}
