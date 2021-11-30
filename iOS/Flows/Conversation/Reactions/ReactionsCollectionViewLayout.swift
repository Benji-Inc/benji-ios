//
//  ReactionsCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReactionsCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = ReactionsCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .reactions:
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(26), heightDimension: .fractionalHeight(1))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Theme.ContentOffset.short.value, bottom: 0, trailing: Theme.ContentOffset.short.value)

                // Section
                let section = NSCollectionLayoutSection(group: group)

                let size = NSCollectionLayoutSize(widthDimension: .absolute(20),
                                                              heightDimension: .fractionalHeight(1.0))
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: size,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .leading)
                let footer = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: size,
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .trailing)
                section.boundarySupplementaryItems = [header, footer]

                return section
            }

        }, configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
