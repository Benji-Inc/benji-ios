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

class MessageSupplier: NSObject {

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

    @Published var messageUpdate: MessageUpdate? = nil
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

    override init() {
        super.init()
        self.subscribeToUpdates()
    }

    deinit {
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }

    private func subscribeToUpdates() {
        ChannelSupplier.shared.$activeChannel.mainSink { [unowned self] (channel) in
            guard let activeChannel = channel else {
                return
            }

            switch activeChannel.channelType {
            case .channel(let channel):
                channel.delegate = self
            default:
                break
            }
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$messageUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }

            guard let messageUpdate = update, ChannelSupplier.shared.isChannelEqualToActiveChannel(channel: messageUpdate.channel) else { return }

            switch messageUpdate.status {
            case .added:
                self.allMessages.append(messageUpdate.message)
            case .changed:
                guard let index = self.findMessageIndex(for: messageUpdate.message) else { return }
                self.allMessages[index] = messageUpdate.message
            case .deleted:
                guard let index = self.findMessageIndex(for: messageUpdate.message) else { return }
                self.allMessages.remove(at: index)
            case .toastReceived:
                break
            }
            // Forwards the update, after the supplier responds so the supplier remains the source of truth
            self.messageUpdate = update
        }.store(in: &self.cancellables)
    }

    private func findMessageIndex(for message: TCHMessage) -> Int? {
        var messageIndex: Int?
        for (index, msg) in self.allMessages.enumerated() {
            if msg == message {
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

    static func getMessage(from channelId: String, with index: NSNumber) async throws -> Messageable {
        let messageable: Messageable = try await withCheckedThrowingContinuation { continuation in
            // Get the channel
            guard let channel = ChannelSupplier.shared.allChannelsSorted.first(where: { channel in
                if case ChannelType.channel(let channel) = channel.channelType {
                    return channel.sid == channelId
                }
                return false
            }) else {
                continuation.resume(throwing: ClientError.apiError(detail: "Channel not found"))
                return
            }

            // Get the messages off of the channel
            guard case ChannelType.channel(let channel) = channel.channelType,
                  let messages = channel.messages else {
                      continuation.resume(throwing: ClientError.apiError(detail: "No messages object"))
                      return
                  }

            messages.message(withIndex: index) { result, message in
                if let msg = message {
                    continuation.resume(returning: msg)
                } else {
                    continuation.resume(throwing: ClientError.apiError(detail: "No message found for index"))
                }
            }
        }

        return messageable
    }

    @discardableResult
    func getLastMessages(batchAmount: UInt = 20) async throws -> [ChannelSectionable] {
        let channelSections: [ChannelSectionable] = try await withCheckedThrowingContinuation { continuation in
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
                        continuation.resume(returning: sections)
                    } else {
                        continuation.resume(throwing: ClientError.message(detail: "Failed to retrieve last messages."))
                    }
                }
            } else {
                continuation.resume(throwing: ClientError.message(detail: "Failed to retrieve last messages."))
            }
        }
        return channelSections
    }

    func getMessages(before index: UInt,
                     batchAmount: UInt = 20,
                     for channel: TCHChannel) async throws -> [ChannelSectionable] {

        let sections: [ChannelSectionable] = try await withCheckedThrowingContinuation { continuation in
            if let messagesObject = channel.messages {
                self.messagesObject = messagesObject
                messagesObject.getBefore(index, withCount: batchAmount) { (result, messages) in
                    if let msgs = messages {
                        self.allMessages.insert(contentsOf: msgs, at: 0)
                        let sections = self.mapMessagesToSections(for: self.allMessages, in: .channel(channel))
                        self.sections = sections
                        continuation.resume(returning: sections)
                    } else {
                        continuation.resume(throwing: ClientError.message(detail: "Failed to retrieve messages."))
                    }
                }
            } else {
                continuation.resume(throwing: ClientError.message(detail: "Failed to retrieve messages."))
            }
        }
        return sections
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

    func update(object: Sendable) -> SystemMessage? {
        guard let previousMessage = object.previousMessage as? TCHMessage else { return nil }

        let updatedMessage = SystemMessage(with: previousMessage)
        updatedMessage.kind = object.kind

        previousMessage.updateBody(object.kind.text) { (result) in
            if let error = result.error {
                print(error)
            }
        }

        return updatedMessage
    }
}

extension MessageSupplier: TCHChannelDelegate {

    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    member: TCHMember,
                    updated: TCHMemberUpdate) {
    }

    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    message: TCHMessage,
                    updated: TCHMessageUpdate) {

        guard let index = self.findMessageIndex(for: message) else { return }
        self.allMessages[index] = message
        self.hasUnreadMessage = self.unreadMessages.count > 0 
        self.messageUpdate = MessageUpdate(channel: channel, message: message, status: .changed)
    }
}
