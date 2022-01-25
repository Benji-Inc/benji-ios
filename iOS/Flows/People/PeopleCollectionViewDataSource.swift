//
//  PeopleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import Localization

class PeopleCollectionViewDataSource: CollectionViewDataSource<PeopleCollectionViewDataSource.SectionType,
                                       PeopleCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case people
    }

    enum ItemType: Hashable {
        case person(Person)
    }

    private let personConfig = ManageableCellRegistration<PersonCell>().provider
    

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .person(let person):
            return collectionView.dequeueConfiguredReusableCell(using: self.personConfig,
                                                                for: indexPath,
                                                                item: person)
        }
    }
}
