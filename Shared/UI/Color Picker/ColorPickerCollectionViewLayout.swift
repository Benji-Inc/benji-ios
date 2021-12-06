//
//  ColorPickerCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ColorPickerCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = ColorPickerCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .colors:
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2), heightDimension: .fractionalHeight(1))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Theme.ContentOffset.screenPadding.value, bottom: 0, trailing: Theme.ContentOffset.screenPadding.value)

                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                                              heightDimension: .fractionalHeight(1.0))

                let footer = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: size,
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .trailing)
                section.boundarySupplementaryItems = [footer]

                return section
            }

        }, configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
