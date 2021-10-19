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
    = UICollectionView.CellRegistration<MessageCell,
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

            let replies = message.latestReplies
            cell.set(message: message, replies: replies, totalReplyCount: message.replyCount)

            // Load in the message's replies if needed, then reconfigure the cell so they show up.
            if message.replyCount > 0 && message.latestReplies.isEmpty {
                let dataSource = item.dataSource
                Task {
                    try? await messageController.loadPreviousReplies()
                    await dataSource.reconfigureItems([.message(item.messageID)])
                }
            }
        }
    }

    static func createThreadMessageCellRegistration() -> MessageCellRegistration {
        return MessageCellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }

            let replies = message.latestReplies
            cell.set(message: message, replies: replies, totalReplyCount: message.replyCount)

            let messageAuthor = message.author
            cell.setAuthor(with: messageAuthor)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreMessagesCellRegistration {
        return LoadMoreMessagesCellRegistration { cell, indexPath, itemIdentifier in
            
        }
    }
}
