//
//  MessageDetailCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDetailCollectionViewLayout: UICollectionViewCompositionalLayout {
    
    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = MessageDetailDataSource.SectionType(rawValue: sectionIndex) else { return nil }
            
            let headerHeight: CGFloat = 20
            let sectionInset = Theme.ContentOffset.long.value

            switch sectionType {
            case .options:
                let inset = Theme.ContentOffset.short.value
                let fraction: CGFloat = 0.25
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                             leading: inset,
                                                             bottom: inset,
                                                             trailing: inset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(fraction))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: sectionInset,
                                                                bottom: sectionInset,
                                                                trailing: sectionInset)
                return section
            case .reads:
                let fraction: CGFloat = 0.2
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: sectionInset + 4,
                                                             leading: 0,
                                                             bottom: 0,
                                                             trailing: 0)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(fraction))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: sectionInset,
                                                                bottom: sectionInset,
                                                                trailing: sectionInset)
                
                let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.kind)
                let backgroundInset: CGFloat = Theme.ContentOffset.xtraLong.value
                backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: headerHeight + backgroundInset,
                                                                       leading: backgroundInset,
                                                                       bottom: backgroundInset - 12,
                                                                       trailing: backgroundInset)
                section.decorationItems = [backgroundItem]
                
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: 8,
                                                                   bottom: -16,
                                                                   trailing: 0)
                section.boundarySupplementaryItems = [headerItem]
                
                return section
            case .metadata:
                
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: sectionInset,
                                                             bottom: 0,
                                                             trailing: sectionInset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: sectionInset,
                                                                bottom: sectionInset,
                                                                trailing: sectionInset)
                
                let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.kind)
                let backgroundInset: CGFloat = Theme.ContentOffset.xtraLong.value
                backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: headerHeight + backgroundInset,
                                                                       leading: backgroundInset,
                                                                       bottom: backgroundInset - 12,
                                                                       trailing: backgroundInset)
                section.decorationItems = [backgroundItem]
                
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(headerHeight))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: 8,
                                                                   bottom: -16,
                                                                   trailing: 0)
                section.boundarySupplementaryItems = [headerItem]
                
                return section
            }
        }, configuration: config)
        
        self.register(SectionBackgroundView.self, forDecorationViewOfKind: SectionBackgroundView.kind)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
}
