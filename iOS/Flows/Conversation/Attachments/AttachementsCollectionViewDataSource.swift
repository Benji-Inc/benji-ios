//
//  AttachementsCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachementsCollectionViewDataSource: CollectionViewDataSource<AttachementsCollectionViewDataSource.SectionType,
                                            AttachementsCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case attachements
    }

    enum ItemType: Hashable {
        case attachment(Attachment)
    }

    private let config = ManageableCellRegistration<AttachmentCell>().provider
    
    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .attachment(let attachment):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: attachment)
        }
    }
}
