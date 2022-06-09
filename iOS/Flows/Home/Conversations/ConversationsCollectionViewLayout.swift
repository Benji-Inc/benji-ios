//
//  ConversationsCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConverssationsCollectionViewLayout: UICollectionViewCompositionalLayout {
        
    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = ConversationsDataSource.SectionType(rawValue: sectionIndex) else { return nil }
            
            let sectionInset = Theme.ContentOffset.xtraLong.value

            switch sectionType {
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
                                                              leading: sectionInset,
                                                              bottom: 0,
                                                              trailing: sectionInset)

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
