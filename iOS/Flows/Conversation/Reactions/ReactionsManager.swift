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
    private var updatedAt: Date?

    override func initializeCollectionView() {
        super.initializeCollectionView()

        self.collectionView.allowsMultipleSelection = false
        self.collectionView.isScrollEnabled = false
    }

    func loadReactions(for message: Message) {
        self.messageController = ChatClient.shared.messageController(cid: message.cid!, messageId: message.id)
        self.subscribeToUpdates(for: message)
        Task {
            await self.reloadReactions()
        }.add(to: self.taskPool)
    }

    @MainActor
    private func reloadReactions() async {
        /// Checks to make sure we have already tried to update
        if self.updatedAt.isNil {
            await self.loadData()
            self.handleDataBeingLoaded()
        } else if let newUpdate = self.messageController?.message?.updatedAt,
            let oldUpdate = self.updatedAt,
        newUpdate > oldUpdate {
            await self.loadData()
            self.handleDataBeingLoaded()
        }
    }

    private func subscribeToUpdates(for message: Message) {

        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }

        self.messageController?.messageChangePublisher.mainSink { [unowned self] output in
            switch output {
            case .create(_):
                break
            case .update(_):
                Task {
                    try? await self.messageController?.synchronize()
                    await self.reloadReactions()
                }.add(to: self.taskPool)
            case .remove(_):
                break
            }
        }.store(in: &self.cancellables)
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

        self.updatedAt = message.updatedAt
        self.dataSource.remainingCount = remaining
        self.dataSource.message = message

        return [.reactions: summaries]
    }

    override func getAllSections() -> [ReactionsCollectionViewDataSource.SectionType] {
        return [.reactions]
    }
}
