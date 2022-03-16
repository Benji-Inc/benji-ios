//
//  ContextCueCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCueCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        super.init(sectionProvider: { sectionIndex, environment in
            guard let sectionType = ContextCueCollectionViewDataSource.SectionType(rawValue: sectionIndex) else { return nil }

            switch sectionType {
            case .contextCues:
                
                let inset = environment.container.contentSize.width.half
                // Item
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                             leading: inset,
                                                             bottom: 0,
                                                             trailing: inset)

                // Group
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

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
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return self.getCellOffset(with: proposedContentOffset)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return self.getCellOffset(with: proposedContentOffset)
    }
    
    private func getCellOffset(with proposed: CGPoint) -> CGPoint {
        guard let cv = self.collectionView else { return .zero }
        let itemWidth = cv.halfWidth
        let currentXOffset = proposed.x
        let targetXOffset = round((currentXOffset / itemWidth) * itemWidth, toNearest: itemWidth)
        return CGPoint(x: targetXOffset, y: proposed.y)
    }
}
