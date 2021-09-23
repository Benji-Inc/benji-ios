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

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        if sendable.previousMessage.isNil {
            Task {
                await self.send(object: sendable)
            }
        }
    }

    @MainActor
    func send(object: Sendable) async {

    }
}
