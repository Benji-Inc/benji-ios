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
                    let object = SendableObject(kind: kind, context: .passive)
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
                                                                            if msg.context == .emergency {
                                                                                self.showAlertSentToast(for: msg)
                                                                            }
                                                                        }
        }) else { return }

        if systemMessage.context == .emergency {
            self.showAlertSentToast(for: systemMessage)
        }

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

    private func showAlertSentToast(for message: SystemMessage) {
        guard let displaybleChannel = self.activeChannel, case ChannelType.channel(let channel) = displaybleChannel.channelType else { return }

        var displayable: ImageDisplayable = User.current()!
                channel.getUsers(excludeMe: true)
                    .mainSink(receiveValue: { (users) in
                        var name: String = ""

                        if let friendlyName = channel.friendlyName {
                            name = friendlyName
                        } else if users.count == 0 {
                            name = "You"
                        } else if users.count == 1, let user = users.first(where: { user in
                            return user.objectId != User.current()?.objectId
                        }) {
                            displayable = user
                            name = user.fullName
                        } else {
                            displayable = users.first!
                            name = self.displayGroupChat(for: channel, with: users)
                        }

                        ToastScheduler.shared.schedule(toastType: .basic(identifier: message.id, displayable: displayable, title: "Notification Sent", description: "A notification linking to your message has been sent to: \(name).", deepLink: nil))
                    }).store(in: &self.cancellables)
    }

    private func displayGroupChat(for channel: TCHChannel, with users: [User]) -> String {
        var text = ""
        for (index, user) in users.enumerated() {
            if index < users.count - 1 {
                text.append(String("\(user.givenName), "))
            } else if index == users.count - 1 && users.count > 1 {
                text.append(String("\(user.givenName)"))
            } else {
                text.append(user.givenName)
            }
        }

        return text
    }
}
