//
//  PeopleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import TMROLocalization

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

    var headerTitle: Localized = ""
    var headerDescription: Localized = ""

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
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.titleLabel.setText(self.headerTitle)
            header.descriptionLabel.setText(self.headerDescription)
            return header 
        default: 
            return nil
        }
    }
}
