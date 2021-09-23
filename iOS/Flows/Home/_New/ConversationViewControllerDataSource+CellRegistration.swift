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
    = UICollectionView.CellRegistration<new_MessageCell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         dataSource: ConversationCollectionViewDataSource)>

    static func createMessageCellRegistration() -> MessageCellRegistration {

        return MessageCellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }
            let dataSource = item.dataSource


            if message.type == .deleted {
                cell.setIsDeleted()
            } else {
                cell.setMessage(message.text)

                let replies = message.latestReplies.map { message in
                    return message.text
                }
                cell.setReplyCount(message.replyCount)
                cell.setReplies(replies)

                // Load in the messages replies if needed, then reconfigure the cell so they show up.
                if message.replyCount > message.latestReplies.count {
                    Task {
                        try? await messageController.loadPreviousReplies()
                        await dataSource.reconfigureItems([.message(item.messageID)])
                    }
                }
            }


            cell.contentView.setNeedsLayout()
        }
    }
}
