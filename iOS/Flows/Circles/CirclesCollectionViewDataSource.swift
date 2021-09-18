//
//  CirclesCollectionViewDataSource.swift
//  CirclesCollectionViewDataSource
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CirclesCollectionViewDataSource: CollectionViewDataSource<CirclesCollectionViewDataSource.SectionType,
                                      CirclesCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case circles
    }

    enum ItemType: Hashable {
        case circles(CircleGroup)
    }

    private let circlesConfig = ManageableCellRegistration<CircleGroupCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .circles(let group):
            return collectionView.dequeueConfiguredReusableCell(using: self.circlesConfig,
                                                                for: indexPath,
                                                                item: group)
        }
    }
}
