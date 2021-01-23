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

    func attachementView(_ controller: AttachmentViewController, didSelect attachment: Attachment) {
        self.handle(attachment: attachment, body: String())
    }

    func handle(attachment: Attachment, body: String) {
        AttachmentsManager.shared.getMessageKind(for: attachment, body: body)
            .mainSink { (result) in
                switch result {
                case .success(let kind):
                    self.send(messageKind: kind, attributes: [:])
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    func messageInputAccessory(_ view: MessageInputAccessoryView, didUpdate message: Messageable, with text: String) {
        self.update(message: message, text: text)
    }

    func messageInputAccessory(_ view: MessageInputAccessoryView, didSend text: String, context: MessageContext, attributes: [String : Any]) {
        self.send(messageKind: .text(text), context: context, attributes: attributes)
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

    func send(messageKind: MessageKind,
              context: MessageContext = .casual,
              attributes: [String : Any]) {

        guard let systemMessage = MessageDeliveryManager.shared.send(context: context,
                                                                     kind: messageKind,
                                                                     attributes: attributes,
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

    func update(message: Messageable, text: String) {
        let updatedMessage = MessageSupplier.shared.update(message: message, text: text) { (msg, error) in
            if let _ = error {
                msg.status = .error
                self.collectionViewManager.updateItem(with: msg)
            }
        }

        self.indexPathForEditing = nil
        self.collectionViewManager.updateItem(with: updatedMessage)
        self.messageInputAccessoryView.reset()
    }
}
