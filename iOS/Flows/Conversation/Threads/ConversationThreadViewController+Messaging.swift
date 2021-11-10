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

extension ConversationThreadViewController: SwipeableInputAccessoryViewDelegate {

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

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {

    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didPrepare sendable: Sendable,
                                 at position: SwipeableInputAccessoryView.SendPosition) {

    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdate sendable: Sendable,
                                 withProgress progress: CGFloat) {

    }

    func swipeableInputAccessoryDidUnprepareSendable(_ view: SwipeableInputAccessoryView) {

    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didConfirm sendable: Sendable,
                                 at position: SwipeableInputAccessoryView.SendPosition) {

        Task {
            await self.send(object: sendable)
        }
    }

    func swipeableInputAccessoryDidFinishSwipe(_ view: SwipeableInputAccessoryView) {

    }

    @MainActor
    func send(object: Sendable) async {
        do {
            try await self.messageController.createNewReply(with: object)
        } catch {
            logDebug(error)
        }
    }
}
