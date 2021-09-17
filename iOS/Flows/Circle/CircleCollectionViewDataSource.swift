//
//  CircleCollectionViewDataSource.swift
//  CircleCollectionViewDataSource
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCollectionViewDataSource: CollectionViewDataSource<CircleCollectionViewDataSource.SectionType,
                                      CircleCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case users
    }

    enum ItemType: Hashable {
        case user(User)
    }

    private let userConfig = ManageableCellRegistration<UserCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .user(let user):
            return collectionView.dequeueConfiguredReusableCell(using: self.userConfig,
                                                                for: indexPath,
                                                                item: user)
        }
    }
}
