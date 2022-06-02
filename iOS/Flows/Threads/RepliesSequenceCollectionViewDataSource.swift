//
//  RepliesSequenceCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RepliesSequenceCollectionViewDataSource: MessageSequenceCollectionViewDataSource {

    override var shouldShowReplies: Bool {
        return false
    }
    
    override func set(messagesController: MessageSequenceController,
                      itemsToReconfigure: [MessageSequenceCollectionViewDataSource.ItemType] = [],
                      showLoadMore: Bool = false) {

        self.messageSequenceController = messagesController

        let allMessages = messagesController.messageArray.filter { message in
            return !message.isDeleted
        }

        // The newest message is at the bottom, so reverse the order.
        var allMessageItems = allMessages.map { message in
            return ItemType.message(messageId: message.id)
        }

        if self.shouldPrepareToSend {
            allMessageItems.append(.placeholder)
        }

        if showLoadMore {
            allMessageItems.insert(.loadMore, at: 1)
        }

        var snapshot = self.snapshot()

        var animateDifference = true
        if snapshot.numberOfItems == 0 {
            animateDifference = false
        }

        // Clear out the sections to make way for a fresh set of messages.
        snapshot.deleteSections(MessageSequenceSection.allCases)
        snapshot.appendSections(MessageSequenceSection.allCases)

        snapshot.appendItems(allMessageItems, toSection: .messages)

        snapshot.reconfigureItems(itemsToReconfigure)

        self.apply(snapshot, animatingDifferences: animateDifference)
    }
}
