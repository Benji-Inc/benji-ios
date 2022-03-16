//
//  ContextCueCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCueCollectionViewDataSource: CollectionViewDataSource<ContextCueCollectionViewDataSource.SectionType,
                                          ContextCueCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case contextCues
    }

    enum ItemType: Hashable {
        case contextCue(ContextCue)
    }

    private let config = ManageableCellRegistration<ContextCueCell>().provider
    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .contextCue(let contextCue):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: contextCue)
        }
    }
}
