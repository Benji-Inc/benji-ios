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
        config.scrollDirection = .vertical

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = EmotionsCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .emotions:
                
                let inset = Theme.ContentOffset.short.value
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(46))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                               leading: inset,
                                                               bottom: inset,
                                                               trailing: inset)

                let sectionInset = Theme.ContentOffset.long.value
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: sectionInset,
                                                                leading: 0,
                                                                bottom: sectionInset,
                                                                trailing: 0)
                return section
            }

        }, configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
