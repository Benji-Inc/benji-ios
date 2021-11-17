//
//  MessageCellRegistration.swift
//  Jibber
//
//  Created by Martin Young on 9/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ConversationCollectionViewDataSource {

    typealias MessageCellRegistration
    = UICollectionView.CellRegistration<ConversationMessagesCell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         dataSource: ConversationCollectionViewDataSource)>
    typealias ConversationCellRegistration
    = UICollectionView.CellRegistration<ConversationMessagesCell,
                                        (channelID: ChannelId,
                                         dataSource: ConversationCollectionViewDataSource)>
    typealias ThreadMessageCellRegistration
    = UICollectionView.CellRegistration<ThreadMessageCell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         dataSource: ConversationCollectionViewDataSource)>
    typealias LoadMoreMessagesCellRegistration
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, String>

    static func createMessageCellRegistration() -> MessageCellRegistration {
        return MessageCellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }

            let replies = Array(messageController.replies)
            cell.set(message: message, replies: replies, totalReplyCount: message.replyCount)

            // Load in the message's replies if needed, then reconfigure the cell so they show up.
            if message.replyCount > 0 && message.latestReplies.isEmpty {
                let dataSource = item.dataSource
                Task {
                    try? await messageController.loadPreviousReplies()
                    await dataSource.reconfigureItems([.messages(item.messageID)])
                }
            }
        }
    }

    static func createConversationCellRegistration() -> ConversationCellRegistration {
        return ConversationCellRegistration { cell, indexPath, item in
            let conversationController = ChatClient.shared.channelController(for: item.channelID)

            let messages = Array(conversationController.messages)
            cell.set(message: conversationController.conversation,
                     replies: messages,
                     totalReplyCount: 0)
            // TODO: Load more messages
        }
    }

    static func createThreadMessageCellRegistration() -> ThreadMessageCellRegistration {
        return ThreadMessageCellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }

            cell.set(message: message, replies: [], totalReplyCount: 0)

            let messageAuthor = message.author

            let dataSource = item.dataSource

            var showTopLine = false
            var showBottomLine = false

            // Connect messages from the same author with a vertical line.
            if let nextItem = dataSource.itemIdentifier(for: IndexPath(item: indexPath.item + 1,
                                                                       section: indexPath.section)) {
                if case .messages(let messageID) = nextItem {
                    let nextMessageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                                    messageId: messageID)
                    if nextMessageController.message?.author == messageAuthor {
                        showTopLine = true
                    }
                }
            }

            if let previousItem = dataSource.itemIdentifier(for: IndexPath(item: indexPath.item - 1,
                                                                           section: indexPath.section)) {
                if case .messages(let messageID) = previousItem {
                    let previousMessageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                                        messageId: messageID)
                    if previousMessageController.message?.author == messageAuthor {
                        showBottomLine = true
                    }
                }
            }

            cell.setAuthor(with: messageAuthor,
                           showTopLine: showTopLine,
                           showBottomLine: showBottomLine)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreMessagesCellRegistration {
        return LoadMoreMessagesCellRegistration { cell, indexPath, itemIdentifier in
            
        }
    }
}
