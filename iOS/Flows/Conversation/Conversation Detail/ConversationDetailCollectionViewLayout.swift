//
//  MembersCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationDetailCollectionViewLayout: UICollectionViewCompositionalLayout {
    
    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = ConversationDetailCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }
            
            let sectionInset: CGFloat = Theme.ContentOffset.xtraLong.value
            
            switch sectionType {
            case .pins:
                let inset = Theme.ContentOffset.short.value
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                             leading: inset,
                                                             bottom: inset,
                                                             trailing: inset)
                
                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(220))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: sectionInset,
                                                                bottom: 0,
                                                                trailing: sectionInset)
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: 0,
                                                                bottom: 20,
                                                                trailing: 0)
                
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                
                return section
            case .people, .options, .info:
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: sectionInset,
                                                             bottom: 0,
                                                             trailing: sectionInset)
                
                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 0,
                                                              trailing: 0)
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: sectionInset,
                                                                bottom: sectionInset,
                                                                trailing: sectionInset)
                
                let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.kind)
                let backgroundInset: CGFloat = Theme.ContentOffset.xtraLong.value
                backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: backgroundInset,
                                                                       leading: backgroundInset,
                                                                       bottom: backgroundInset,
                                                                       trailing: backgroundInset)
                section.decorationItems = [backgroundItem]
                
                return section
            }
            
        }, configuration: config)
        
        self.register(SectionBackgroundView.self, forDecorationViewOfKind: SectionBackgroundView.kind)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
