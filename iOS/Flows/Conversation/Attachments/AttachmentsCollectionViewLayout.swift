//
//  AttachmentsCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentCollectionViewLayout: UICollectionViewCompositionalLayout {
    
    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        super.init(sectionProvider: { sectionIndex, environment in
            guard let section = AttachmentsCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }
            
            let screenPadding = Theme.ContentOffset.xtraLong.value
            switch section {
            case .photoVideo:
                let inset = Theme.ContentOffset.short.value
                let fraction: CGFloat = 0.33
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                             leading: inset,
                                                             bottom: inset,
                                                             trailing: inset)
                
                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalWidth(fraction))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: screenPadding,
                                                                bottom: 0,
                                                                trailing: screenPadding)
                
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: 0,
                                                                   bottom: 0,
                                                                   trailing: 0)
                section.boundarySupplementaryItems = [headerItem]
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                
                return section
                
            case .other:
                
                let inset = Theme.ContentOffset.short.value
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                             leading: 0,
                                                             bottom: inset,
                                                             trailing: 0)
                
                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: screenPadding,
                                                                bottom: 0,
                                                                trailing: screenPadding)
                
                let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(Theme.ContentOffset.xtraLong.value))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: 0,
                                                                   bottom: 0,
                                                                   trailing: 0)
                section.boundarySupplementaryItems = [headerItem]
                
                return section
            }
            
        }, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
