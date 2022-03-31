//
//  CircleCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RoomCollectionViewLayout: UICollectionViewCompositionalLayout {
    
    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = RoomCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }
            
            let sectionInset = Theme.ContentOffset.xtraLong.value

            switch sectionType {
            case .members:
                let inset = Theme.ContentOffset.short.value
                let fraction: CGFloat = 0.333
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
            case .conversations:

                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: sectionInset,
                                                             bottom: 0,
                                                             trailing: sectionInset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 0,
                                                              trailing: 0)

                // Section
                let section = NSCollectionLayoutSection(group: group)
                
                let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.kind)
                backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: -sectionInset.half,
                                                                       leading: sectionInset,
                                                                       bottom: -sectionInset.half,
                                                                       trailing: sectionInset)
                section.decorationItems = [backgroundItem]
                
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: sectionInset.doubled,
                                                                   bottom: 0,
                                                                   trailing: sectionInset.doubled)
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
