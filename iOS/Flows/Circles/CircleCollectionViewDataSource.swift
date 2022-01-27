//
//  CircleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


typealias CircleSectionType = CircleCollectionViewDataSource.SectionType
typealias CircleItemType = CircleCollectionViewDataSource.ItemType

class CircleCollectionViewDataSource: CollectionViewDataSource<CircleSectionType, CircleItemType> {

    enum SectionType: Int, CaseIterable {
        case circle
    }

    enum ItemType: Hashable {
        case item(CircleItem)
    }

    private let config = ManageableCellRegistration<CircleCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .item(let foo):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: foo)
        }
    }
}
