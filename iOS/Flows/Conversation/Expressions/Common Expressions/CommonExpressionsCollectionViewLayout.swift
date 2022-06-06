//
//  CommonExpressionsCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


class CommonExpressionsCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = CommonExpressionsDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .expressions:
                
                let inset = Theme.ContentOffset.short.value
                let fraction: CGFloat = 0.2
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: inset,
                                                             leading: inset,
                                                             bottom: inset,
                                                             trailing: inset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let sectionInset = Theme.ContentOffset.long.value
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: 0,
                                                                bottom: 0,
                                                                trailing: 0)
                return section
            }

        }, configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
