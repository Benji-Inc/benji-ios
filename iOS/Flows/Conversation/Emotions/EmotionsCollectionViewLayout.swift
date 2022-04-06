//
//  EmotionsCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        super.init(sectionProvider: { sectionIndex, environment in

            let sectionInset = Theme.ContentOffset.xtraLong.value
            
            let inset = Theme.ContentOffset.short.value
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .absolute(30))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6), heightDimension: .fractionalHeight(1.0))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                           leading: inset,
                                                           bottom: inset,
                                                           trailing: inset)

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                            leading: inset,
                                                            bottom: sectionInset,
                                                            trailing: inset)
            let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6), heightDimension: .estimated(30))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                               leading: 0,
                                                               bottom: 0,
                                                               trailing: 0)
            section.boundarySupplementaryItems = [headerItem]
            
            let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.kind)
            let backgroundInset: CGFloat = Theme.ContentOffset.xtraLong.value
            backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: backgroundInset,
                                                                   leading: backgroundInset,
                                                                   bottom: backgroundInset,
                                                                   trailing: backgroundInset)
            section.decorationItems = [backgroundItem]
            
            return section

        }, configuration: config)
        
        self.register(SectionBackgroundView.self, forDecorationViewOfKind: SectionBackgroundView.kind)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
