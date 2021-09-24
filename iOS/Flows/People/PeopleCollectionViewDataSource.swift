//
//  PeopleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

class PeopleCollectionViewDataSource: CollectionViewDataSource<PeopleCollectionViewDataSource.SectionType,
                                       PeopleCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case connections
        case contacts
    }

    enum ItemType: Hashable {
        case connection(Connection)
        case contact(CNContact)
    }

    private let connectionConfig = ManageableCellRegistration<ConnectionCell>().provider
    private let contactConfig = ManageableCellRegistration<ContactCell>().provider
    private let headerConfig = UICollectionView.SupplementaryRegistration
    <PeopleHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in }

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .connection(let connection):
            return collectionView.dequeueConfiguredReusableCell(using: self.connectionConfig,
                                                                for: indexPath,
                                                                item: connection)

        case .contact(let contact):
            return collectionView.dequeueConfiguredReusableCell(using: self.contactConfig,
                                                                for: indexPath,
                                                                item: contact)
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String, section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
        default: 
            return nil
        }
    }
}
