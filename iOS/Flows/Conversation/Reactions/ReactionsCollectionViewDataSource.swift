//
//  ReactionsCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ReactionsCollectionViewDataSource: CollectionViewDataSource<ReactionsCollectionViewDataSource.SectionType, ReactionSummary> {

    enum SectionType: Int, CaseIterable {
        case reactions
    }

    private let config = ManageableCellRegistration<ReactionsCell>().provider
    private let headerConfig = ManageableHeaderRegistration<AddReactionView>().provider
    private let footerConfig = ManageableFooterRegistration<ReactionsCountView>().provider

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ReactionSummary) -> UICollectionViewCell? {

        return collectionView.dequeueConfiguredReusableCell(using: self.config, for: indexPath, item: item)
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String, section: SectionType, indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
            if let item = self.itemIdentifier(for: indexPath) {
                //footer.configure(with: item)
            }
            return footer
        default:
            break
        }

        return nil
    }
}
