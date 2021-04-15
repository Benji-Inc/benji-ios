//
//  ChannelViewController+Messaging.swift
//  Benji
//
//  Created by Benji Dodgson on 6/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Photos

extension ChannelViewController: SwipeableInputAccessoryViewDelegate {

    func handle(attachment: Attachment, body: String) {
        AttachmentsManager.shared.getMessageKind(for: attachment, body: body)
            .mainSink { (result) in
                switch result {
                case .success(let kind):
                    let object = SendableObject(kind: kind, context: .casual)
                    self.send(object: object)
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        if sendable.previousMessage.isNil {
            self.send(object: sendable)
        } else {
            self.update(object: sendable)
        }
    }

    func load(activeChannel: DisplayableChannel) {
        switch activeChannel.channelType {
        case .system(_):
            break
        case .pending(_):
            break
        case .channel(_):
            self.loadMessages(for: activeChannel.channelType)
        }
    }

    func send(object: Sendable) {

        guard let systemMessage = MessageDeliveryManager.shared.send(object: object,
                                                                     attributes: [:],
                                                                     completion: { (message, error) in
                                                                        if let msg = message, let _ = error {
                                                                            msg.status = .error
                                                                            self.collectionViewManager.updateItem(with: msg)
                                                                        }
        }) else { return }

        self.collectionViewManager.append(item: systemMessage) { [unowned self] in
            self.channelCollectionView.scrollToEnd()
        }

        self.messageInputAccessoryView.reset()
    }

    func resend(message: Messageable) {
        
        guard let systemMessage = MessageDeliveryManager.shared.resend(message: message, completion: { (newMessage, error) in
            if let msg = newMessage, let _ = error {
                msg.status = .error
                self.collectionViewManager.updateItem(with: msg)
            }
        }) else { return }

        self.collectionViewManager.updateItem(with: systemMessage)
    }

    func update(object: Sendable) {
        if let updatedMessage = MessageSupplier.shared.update(object: object) {
            self.indexPathForEditing = nil
            self.collectionViewManager.updateItem(with: updatedMessage)
            self.messageInputAccessoryView.reset()
        }
    }
}
