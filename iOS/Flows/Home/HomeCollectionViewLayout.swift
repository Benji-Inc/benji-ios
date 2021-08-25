//
//  HomeCollectionViewLayout.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class HomeCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical

        super.init(sectionProvider: { sectionIndex, enviroment in

            guard let sectionType = HomeCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }
            switch sectionType {
            case .notices:
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: Theme.contentOffset, bottom: 8, trailing: Theme.contentOffset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(180))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                section.visibleItemsInvalidationHandler = { (items, offset, environment) in
                    items.forEach { item in
                        let distanceFromCenter = abs((item.frame.midX - offset.x) - environment.container.contentSize.width / 2.0)
                        let minScale: CGFloat = 0.7
                        let maxScale: CGFloat = 1.0
                        let scale = max(maxScale - (distanceFromCenter / environment.container.contentSize.width), minScale)
                        item.transform = CGAffineTransform(scaleX: scale, y: scale)
                    }
                }

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

                section.boundarySupplementaryItems = [header]

                return section
            case .channels:
                let widthFraction: CGFloat = 0.5
                let heightFraction: CGFloat = 0.45

                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(widthFraction), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let inset: CGFloat = 5
                item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(heightFraction))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Theme.contentOffset, bottom: 0, trailing: Theme.contentOffset)

                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)

                section.boundarySupplementaryItems = [footer]

                return section
            }

        }, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
