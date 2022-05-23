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
    private let footerConfig = ManageableFooterRegistration<PeopleFooterView>().provider
    
    var didSelectAddContacts: CompletionOptional = nil
        
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
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
        footer.button.isHidden = ContactsManager.shared.hasPermissions
        footer.label.isHidden = ContactsManager.shared.hasPermissions
        footer.didSelectButton = { [unowned self] in
            self.didSelectAddContacts?()
        }
        return footer
    }
}
