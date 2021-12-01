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

    var remainingCount: Int = 0
    var message: Message?

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ReactionSummary) -> UICollectionViewCell? {

        return collectionView.dequeueConfiguredReusableCell(using: self.config, for: indexPath, item: item)
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String, section: SectionType, indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.message = self.message
            return header
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
            footer.configure(with: self.remainingCount)
            return footer
        default:
            break
        }

        return nil
    }
}
