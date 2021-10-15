//
//  ConversationViewController+Updates.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ConversationThreadViewController {

    func subscribeToUpdates() {
        self.messageController.repliesChangesPublisher.mainSink { [unowned self] changes in
            Task {
                await self.update(with: changes,
                                  controller: self.messageController,
                                  collectionView: self.collectionView)
            }
        }.store(in: &self.cancellables)
    }

    /// Updates the datasource with the passed in array of message changes.
    func update(with changes: [ListChange<Message>],
                controller: MessageController,
                collectionView: UICollectionView) async {

//        guard let conversation = controller.message?.cid else { return }
//
//        var snapshot = self.collectionViewDataSource.snapshot()
//
//        let sectionID = ConversationCollectionSection.conversation(conversation)
//
//        // If there's more than one change, reload all of the data.
//        guard changes.count == 1 else {
//            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
//            snapshot.appendItems(controller.replies.asConversationCollectionItems,
//                                 toSection: sectionID)
//            if !controller.hasLoadedAllPreviousReplies {
//                snapshot.appendItems([.loadMore], toSection: sectionID)
//            }
//            await self.collectionViewDataSource.apply(snapshot)
//            return
//        }
//
//        // If this gets set to true, we should scroll to the most recent message after applying the snapshot
//        var scrollToLatestMessage = false
//
//        for change in changes {
//            switch change {
//            case .insert(let message, let index):
//                snapshot.insertItems([.message(message.id)],
//                                     in: sectionID,
//                                     atIndex: index.item)
//                if message.isFromCurrentUser {
//                    scrollToLatestMessage = true
//                }
//            case .move:
//                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
//                snapshot.appendItems(controller.replies.asConversationCollectionItems,
//                                     toSection: sectionID)
//            case .update(let message, _):
//                snapshot.reconfigureItems([message.asConversationCollectionItem])
//            case .remove(let message, _):
//                snapshot.deleteItems([message.asConversationCollectionItem])
//            }
//        }
//
//        // Only show the load more cell if there are previous messages to load.
//        snapshot.deleteItems([.loadMore])
//        if !controller.hasLoadedAllPreviousReplies {
//            snapshot.appendItems([.loadMore], toSection: sectionID)
//        }
//
//        await Task.onMainActorAsync { [snapshot = snapshot, scrollToLatestMessage = scrollToLatestMessage] in
//            self.collectionViewDataSource.apply(snapshot)
//
//            if scrollToLatestMessage, let sectionIndex = snapshot.indexOfSection(sectionID) {
//                let firstIndex = IndexPath(item: 0, section: sectionIndex)
//                collectionView.scrollToItem(at: firstIndex, at: .centeredHorizontally, animated: true)
//            }
//        }
    }
}
