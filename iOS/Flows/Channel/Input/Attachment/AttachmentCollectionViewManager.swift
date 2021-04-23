//
//  AttachentCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentCollectionViewManager: CollectionViewManager<AttachmentCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case photos
    }

    var didSelectPhotoOption: CompletionOptional = nil
    var didSelectLibraryOption: CompletionOptional = nil

    private let cellConfig = ManageableCellRegistration<AttachmentCell>().provider

    private let headerConfig = UICollectionView.SupplementaryRegistration
    <AttachmentHeaderView>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return AttachmentsManager.shared.attachments
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return self.collectionView.dequeueManageableCell(using: self.cellConfig,
                                                         for: indexPath,
                                                         item: item as? Attachment)
    }

    override func getSupplementaryView(for section: SectionType, kind: String, indexPath: IndexPath) -> UICollectionReusableView? {

        let header = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)

        header.photoButton.didSelect { [unowned self] in
            self.didSelectPhotoOption?()
        }

        header.libraryButton.didSelect { [unowned self] in
            self.didSelectLibraryOption?()
        }

        return header

    }

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let value = collectionView.height * 0.5 - (layout.minimumLineSpacing * 0.5)
        return CGSize(width: value, height: value)
    }

    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard collectionView.numberOfItems(inSection: section) > 0 else { return .zero }
        return CGSize(width: 70, height: collectionView.height)
    }
}
