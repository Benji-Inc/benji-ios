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

extension ChannelViewController: InputAccessoryDelegates {

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

    func messageInputAccessory(_ view: InputAccessoryView, didConfirm sendable: SendableType) {
        switch sendable {
        case .update(let object):
            self.update(object: object)
        case .new(let object):
            self.send(object: object)
        }
    }

//    func messageInputAccessory(_ view: MessageInputAccessoryView,
//                               didUpdate message: Messageable,
//                               with text: String) {
//       // self.update(message: message, text: text)
//    }

//    func messageInputAccessory(_ view: MessageInputAccessoryView,
//                               didSend kind: MessageKind,
//                               context: MessageContext,
//                               attributes: [String : Any]) {
//
//        self.send(messageKind: kind, context: context, attributes: attributes)
//    }

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

    func send(object: SendableObject) {

        guard let systemMessage = MessageDeliveryManager.shared.send(object: object,
                                                                     attributes: [:],
                                                                     completion: { (message, error) in
                                                                        if let msg = message, let _ = error {
                                                                            msg.status = .error
                                                                            self.collectionViewManager.updateItem(with: msg)
                                                                        }
        }) else { return }

        self.collectionViewManager.append(item: systemMessage) { [unowned self] in
            self.collectionView.scrollToEnd()
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

    func update(object: ResendableObject) {
        let updatedMessage = MessageSupplier.shared.update(object: object)
        self.indexPathForEditing = nil
        self.collectionViewManager.updateItem(with: updatedMessage)
        self.messageInputAccessoryView.reset()
    }
}
