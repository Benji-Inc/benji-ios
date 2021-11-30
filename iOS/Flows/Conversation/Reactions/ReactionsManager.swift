//
//  ReactionsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ReactionsManager: DiffableCollectionViewManager<ReactionsCollectionViewDataSource.SectionType,
                        Set<ChatMessageReaction>,
                        ReactionsCollectionViewDataSource> {

    override func initializeCollectionView() {
        super.initializeCollectionView()

        self.collectionView.allowsMultipleSelection = false
        self.collectionView.isScrollEnabled = false
    }

    // MARK: Overrides

    override func retrieveDataForSnapshot() async -> [ReactionsCollectionViewDataSource.SectionType: [Set<ChatMessageReaction>]] {
        let items: [Set<ChatMessageReaction>] = []
        return [.reactions: [items]]
    }

    override func getAllSections() -> [ReactionsCollectionViewDataSource.SectionType] {
        return [.reactions]
    }
}
