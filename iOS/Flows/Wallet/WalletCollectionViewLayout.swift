//
//  WalletCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical

        super.init(sectionProvider: { sectionIndex, environment in
            
            guard let sectionType = WalletCollectionViewDataSource.SectionType.init(rawValue: sectionIndex) else { return nil }
            
            switch sectionType {
            case .wallet:
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                let headerHeight = 270 + Theme.ContentOffset.screenPadding.value
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: Theme.ContentOffset.xtraLong.value,
                                                                   bottom: Theme.ContentOffset.xtraLong.value,
                                                                   trailing: Theme.ContentOffset.xtraLong.value)
                section.boundarySupplementaryItems = [headerItem]
                
                return section
            case .transactions:
                
                let sectionInset: CGFloat = Theme.ContentOffset.xtraLong.value

                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: sectionInset,
                                                             bottom: 0,
                                                             trailing: sectionInset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: sectionInset,
                                                              bottom: 0,
                                                              trailing: sectionInset)

                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 70,
                                                                leading: 0,
                                                                bottom: 0,
                                                                trailing: 0)
                
                let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: BackgroundSupplementaryView.kind)
                let backgroundInset: CGFloat = Theme.ContentOffset.xtraLong.value
                backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                       leading: backgroundInset,
                                                                       bottom: -backgroundInset,
                                                                       trailing: backgroundInset)
                
                let headerAnchor = NSCollectionLayoutAnchor(edges: [.top], absoluteOffset: CGPoint(x: 0, y: 0))
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: TransactionSegmentControlView.kind, containerAnchor: headerAnchor)
                
                section.boundarySupplementaryItems = [headerItem]
                section.decorationItems = [backgroundItem]

                return section
            }
                        
        }, configuration: config)
        
        self.register(BackgroundSupplementaryView.self, forDecorationViewOfKind: BackgroundSupplementaryView.kind)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
