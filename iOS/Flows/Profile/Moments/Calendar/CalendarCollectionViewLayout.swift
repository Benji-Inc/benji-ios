//
//  CalendarCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CalendarCollectionViewLayout: UICollectionViewCompositionalLayout {
    
    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        super.init(sectionProvider: { sectionIndex, environment in
            
            let groupInset = Theme.ContentOffset.short.value
            
            let fractionWidth: CGFloat = 1 / 7
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionWidth), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                         leading: groupInset,
                                                         bottom: 0,
                                                         trailing: groupInset)
            
            let groupHeight = (environment.container.contentSize.width * fractionWidth) * 1.5
            
            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(groupHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            group.contentInsets = NSDirectionalEdgeInsets(top: groupInset,
                                                          leading: 0,
                                                          bottom: groupInset,
                                                          trailing: 0)
            // Section
            let section = NSCollectionLayoutSection(group: group)
            let inset = Theme.ContentOffset.xtraLong.value
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: inset - groupInset,
                                                            bottom: 0,
                                                            trailing: inset - groupInset)
            
            let headerItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40))
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerItemSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            
            section.boundarySupplementaryItems = [headerItem]
            return section
            
        }, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
