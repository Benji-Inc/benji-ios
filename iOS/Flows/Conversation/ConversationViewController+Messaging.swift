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

    func load(conversation: Conversation) {
        self.loadMessages(for: conversation)
    }

    @MainActor
    func send(object: Sendable) async {
        guard let conversation = self.conversation else { return }

        do {
            if case .text(let body) = object.kind {
                let controller = chatClient.channelController(for: conversation.cid)
                try await controller.createNewMessage(text: body)

                self.conversationCollectionView.scrollToEnd()
            }
        } catch {
            logDebug(error)
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
