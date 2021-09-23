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

                for change in changes {
                    switch change {
                    case .insert(let message, _):
                        self.collectionViewManager.append(item: message, completion: nil)
                    case .move(_, _, _):
                        return
                    case .update(_, _):
                        return
                    case .remove(_, _):
                        return
                    }
                }
            }.store(in: &self.cancellables)
    }
}
