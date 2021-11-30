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

    func loadReactions(for message: Message) {
        self.messageController = ChatClient.shared.messageController(cid: message.cid!, messageId: message.id)
        self.reloadReactions()
    }

    private func reloadReactions() {
        Task {
            await self.loadData()
            self.handleDataBeingLoaded()
        }.add(to: self.taskPool)
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
                self.reloadReactions()
            case .remove(_):
                break
            }
        }.store(in: &self.cancellables)
    }

    // MARK: Overrides

    override func retrieveDataForSnapshot() async -> [ReactionsCollectionViewDataSource.SectionType: [ReactionSummary]] {
        guard let allReactions = self.messageController?.message?.reactionCounts else { return [.reactions: []] }

        var summaries: [ReactionSummary] = []

        allReactions.keys.forEach { type in
            if let t = ReactionType(rawValue: type.rawValue),
                let count = allReactions[type],
               summaries.count <= 3 {
                let summary = ReactionSummary(type: t, count: count)
                summaries.append(summary)
            }
        }

        return [.reactions: summaries]
    }

    override func getAllSections() -> [ReactionsCollectionViewDataSource.SectionType] {
        return [.reactions]
    }
}
