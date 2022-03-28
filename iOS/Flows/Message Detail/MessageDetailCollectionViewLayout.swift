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

                let sectionInset = Theme.ContentOffset.long.value
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: sectionInset,
                                                                bottom: sectionInset,
                                                                trailing: sectionInset)
                return section
            case .reads:
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

                let sectionInset = Theme.ContentOffset.long.value
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
                                                                       bottom: backgroundInset - 12,
                                                                       trailing: backgroundInset)
                section.decorationItems = [backgroundItem]
                return section
            case .recentReply:
                let sectionInset: CGFloat = Theme.ContentOffset.xtraLong.value

                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: sectionInset,
                                                             bottom: 0,
                                                             trailing: sectionInset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(120))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 0,
                                                              trailing: 0)

                // Section
                let section = NSCollectionLayoutSection(group: group)
                
                let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: SectionBackgroundView.kind)
                let backgroundInset: CGFloat = Theme.ContentOffset.xtraLong.value
                backgroundItem.contentInsets = NSDirectionalEdgeInsets(top: backgroundInset,
                                                                       leading: backgroundInset,
                                                                       bottom: backgroundInset - 12,
                                                                       trailing: backgroundInset)
                section.decorationItems = [backgroundItem]
                return section
                
            case .metadata:
                return nil
            }
            
//            let sectionInset: CGFloat = Theme.ContentOffset.xtraLong.value
            
//            switch sectionType {
//            case :
                // Item
//                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
//                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
//                                                             leading: sectionInset,
//                                                             bottom: 0,
//                                                             trailing: sectionInset)
//
//                // Group
//                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
//                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
//                                                              leading: 0,
//                                                              bottom: 0,
//                                                              trailing: 0)
//
//                // Section
//                let section = NSCollectionLayoutSection(group: group)
//                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
//                                                                leading: sectionInset,
//                                                                bottom: sectionInset,
//                                                                trailing: sectionInset)
//

//
//                return section
            //}
            
        }, configuration: config)
        
        self.register(SectionBackgroundView.self, forDecorationViewOfKind: SectionBackgroundView.kind)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
