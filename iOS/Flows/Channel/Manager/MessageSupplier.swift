//
//  MessageSupplier.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

class MessageSupplier {

    static let shared = MessageSupplier()

    /// To paginate and keep messages sorted we need to maintain a list
    private(set) var allMessages: [Messageable] = [] {
        didSet {
            self.hasUnreadMessage = self.unreadMessages.count > 0
        }
    }
    private(set) var sections: [ChannelSectionable] = []
    private var messagesObject: TCHMessages?

    private var cancellables = Set<AnyCancellable>()

    @Published var hasUnreadMessage: Bool = false

    var unreadMessages: [Messageable] {
        return self.allMessages.compactMap { (message) -> Messageable? in
            guard !message.isFromCurrentUser,
                let userID = User.current()?.objectId,
                !message.hasBeenConsumedBy.contains(userID),
                message.context != .status  else { return nil }
            
            return message
        }
    }

    var didGetLastSections: (([ChannelSectionable]) -> Void)?

    init() {
        self.subscribeToUpdates()
    }

    deinit {
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }

    private func subscribeToUpdates() {
        ChatClientManager.shared.$messageUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }

            guard let messageUpdate = update, ChannelSupplier.shared.isChannelEqualToActiveChannel(channel: messageUpdate.channel) else { return }

            switch messageUpdate.status {
            case .added:
                self.allMessages.append(messageUpdate.message)
            case .changed:
                guard let index = self.findMessageIndex(for: messageUpdate) else { return }
                self.allMessages[index] = messageUpdate.message
            case .deleted:
                guard let index = self.findMessageIndex(for: messageUpdate) else { return }
                self.allMessages.remove(at: index)
            case .toastReceived:
                break
            }
        }.store(in: &self.cancellables)
    }

    private func findMessageIndex(for messageUpdate: MessageUpdate) -> Int? {
        var messageIndex: Int?
        for (index, message) in self.allMessages.enumerated() {
            if message == messageUpdate.message {
                messageIndex = index
                break
            }
        }

        return messageIndex
    }

    func reset() {
        self.allMessages = []
        self.sections = []
        self.messagesObject = nil 
    }

    //MARK: GET MESSAGES

    @discardableResult
    func getLastMessages(batchAmount: UInt = 20) -> Future<[ChannelSectionable], Error> {
        return Future { promise in
            var tchChannel: TCHChannel?

            if let activeChannel = ChannelSupplier.shared.activeChannel {
                switch activeChannel.channelType {
                case .system(_):
                    break
                case .pending(_):
                    break
                case .channel(let channel):
                    tchChannel = channel
                }
            }

            if let channel = tchChannel, let messagesObject = channel.messages {
                self.messagesObject = messagesObject
                messagesObject.getLastWithCount(batchAmount) { (result, messages) in
                    if let msgs = messages {
                        self.allMessages = msgs
                        let sections = self.mapMessagesToSections(for: msgs, in: .channel(channel))
                        self.sections = sections
                        promise(.success(sections))
                    } else {
                        promise(.failure(ClientError.message(detail: "Failed to retrieve last messages.")))
                    }
                    self.didGetLastSections?(self.sections)
                }
            } else {
                promise(.failure(ClientError.message(detail: "Failed to retrieve last messages.")))
            }
        }
    }

    func getMessages(before index: UInt,
                     batchAmount: UInt = 20,
                     for channel: TCHChannel) -> Future<[ChannelSectionable], Error> {
        return Future { promise in
            if let messagesObject = channel.messages {
                self.messagesObject = messagesObject
                messagesObject.getBefore(index, withCount: batchAmount) { (result, messages) in
                    if let msgs = messages {
                        self.allMessages.insert(contentsOf: msgs, at: 0)
                        let sections = self.mapMessagesToSections(for: self.allMessages, in: .channel(channel))
                        self.sections = sections
                        promise(.success(sections))
                    } else {
                        promise(.failure(ClientError.message(detail: "Failed to retrieve messages.")))
                    }
                }
            } else {
                promise(.failure(ClientError.message(detail: "Failed to retrieve messages.")))
            }
        }
    }

    func mapMessagesToSections(for messages: [Messageable], in channelable: ChannelType) -> [ChannelSectionable] {

        var sections: [ChannelSectionable] = []

        messages.forEach { (message) in

            // Determine if the message is a part of the latest channel section
            let messageCreatedAt = message.createdAt

            if let latestSection = sections.last, latestSection.date.isSameDay(as: messageCreatedAt) {
                // If the message fits into the latest section, then just append it
                latestSection.items.append(message)
            } else {
                // Otherwise, create a new section with the date of this message
                let section = ChannelSectionable(date: messageCreatedAt.beginningOfDay,
                                                 items: [message],
                                                 channelType: channelable)
                sections.append(section)
            }
        }

        return sections
    }

    func delete(message: Messageable) {
        guard let tchMessage = message as? TCHMessage, let messagesObject = self.messagesObject else { return }
        messagesObject.remove(tchMessage, completion: nil)
    }

    func update(message: Messageable, text: String, completion: ((SystemMessage, Error?) -> Void)?) -> SystemMessage {

        let updatedMessage = SystemMessage(with: message)
        updatedMessage.kind = .text(text)

        if let tchMessage = message as? TCHMessage {
            tchMessage.updateBody(text) { (result) in
                if let error = result.error {
                    completion?(updatedMessage, error)
                } else {
                    completion?(updatedMessage, nil)
                }
            }
        }

        return updatedMessage
    }
}
