//
//  MembersCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

typealias MembersSectionType = MembersCollectionViewDataSource.SectionType
typealias MembersItemType = MembersCollectionViewDataSource.ItemType

class MembersCollectionViewDataSource: CollectionViewDataSource<MembersCollectionViewDataSource.SectionType, MembersCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case members
    }

    enum ItemType: Hashable {
        case member(Member)
    }

    private let memberConfig = ManageableCellRegistration<MemberCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .member(let member):
            return collectionView.dequeueConfiguredReusableCell(using: self.memberConfig,
                                                                for: indexPath,
                                                                item: member)
        }
    }
}
