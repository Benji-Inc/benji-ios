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

    @MainActor
    func loadReplies(for message: Message) async {
        self.collectionViewManager.reset()

        do {
            try await self.messageController.loadPreviousReplies()
            let messages: [Messageable] = self.messageController.replies.reversed()
            let section = ConversationSectionable(date: message.updatedAt,
                                                  items: messages)

            self.collectionViewManager.set(newSections: [section], animate: true, completion: nil)
        } catch {
            logDebug(error)
        }
    }

    func subscribeToUpdates() {
        self.messageController.repliesChangesPublisher
            .mainSink { [weak self] (changes: [ListChange<ChatMessage>]) in
                guard let `self` = self else { return }

                // If there's more than one change, reload all of the data.
                guard changes.count == 1 else {
                    let messages: [Messageable] = self.messageController.replies.reversed()
                    let section = ConversationSectionable(date: self.message.updatedAt,
                                                          items: messages)
                    self.collectionViewManager.set(newSections: [section], animate: true, completion: nil)
                    return
                }


                for change in changes {
                    switch change {
                    case .insert(let message, _):
                        self.collectionViewManager.append(item: message) {
                            self.collectionView.scrollToEnd()
                        }
                    case .move:
                        let messages: [Messageable] = self.messageController.replies.reversed()
                        let section = ConversationSectionable(date: self.message.updatedAt,
                                                              items: messages)
                        self.collectionViewManager.set(newSections: [section], animate: true, completion: nil)
                        return
                    case .update(let message, _):
                        self.collectionViewManager.updateItemSync(with: message)
                    case .remove(let message, _):
                        self.collectionViewManager.delete(item: message)
                    }
                }
            }.store(in: &self.cancellables)
    }
}
