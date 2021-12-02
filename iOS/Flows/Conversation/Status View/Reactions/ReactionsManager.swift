//
//  ReactionsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class ReactionsManager: DiffableCollectionViewManager<ReactionsCollectionViewDataSource.SectionType,
                        ReactionSummary,
                        ReactionsCollectionViewDataSource> {

    private var cancellables = Set<AnyCancellable>()
    private var messageController: ChatMessageController?

    override func initializeCollectionView() {
        super.initializeCollectionView()

        self.collectionView.allowsMultipleSelection = false
        self.collectionView.isScrollEnabled = false
    }

    func loadReactions(for message: Messageable) {
        self.messageController = ChatClient.shared.messageController(for: message)
        Task {
            await self.loadData()
            self.handleDataBeingLoaded()
        }.add(to: self.taskPool)
    }

    // MARK: Overrides

    override func retrieveDataForSnapshot() async -> [ReactionsCollectionViewDataSource.SectionType: [ReactionSummary]] {
        guard let message = self.messageController?.message else { return [.reactions: []] }

        let allReactions = message.reactionCounts
        var summaries: [ReactionSummary] = []
        var remaining: Int = 0

        allReactions.keys.forEach { type in
            if let count = allReactions[type] {
                if let t = ReactionType(rawValue: type.rawValue), t != .read {
                    remaining += count
                    if summaries.count <= 3 {
                        let summary = ReactionSummary(type: t, count: count)
                        summaries.append(summary)
                        remaining -= count
                    }
                }
            }
        }

        self.dataSource.remainingCount = remaining
        self.dataSource.message = message

        return [.reactions: summaries]
    }

    override func getAllSections() -> [ReactionsCollectionViewDataSource.SectionType] {
        return [.reactions]
    }
}
