//
//  AttachmentCollectionViewDataSource.swift
//  Jibber
//
//  Created by Martin Young on 9/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

typealias AttachmentCollectionSection = AttachmentCollectionViewDataSource.SectionType
typealias AttachmentCollectionItem = AttachmentCollectionViewDataSource.ItemType

class AttachmentCollectionViewDataSource: CollectionViewDataSource<AttachmentCollectionSection,
                                          AttachmentCollectionItem> {

    enum SectionType: Hashable {
        case photos
    }

    enum ItemType: Hashable {
        case attachment(attachment: Attachment)
    }

    var didSelectPhotoOption: CompletionOptional = nil
    var didSelectLibraryOption: CompletionOptional = nil

    private let attachmentCellRegistration = ManageableCellRegistration<AttachmentCell>().provider

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .attachment(let attachment):
            return collectionView.dequeueConfiguredReusableCell(using: self.attachmentCellRegistration,
                                                                for: indexPath,
                                                                item: attachment)

        }
    }
}
