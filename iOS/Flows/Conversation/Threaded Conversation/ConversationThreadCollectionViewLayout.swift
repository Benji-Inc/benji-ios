//
//  ConversationThreadCollectionViewLayout.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationThreadCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical

        super.init(sectionProvider: { sectionIndex, environment in

            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: Theme.contentOffset, bottom: 8, trailing: Theme.contentOffset)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: Theme.contentOffset - 8, leading: 0, bottom: Theme.contentOffset.doubled.doubled, trailing: 0)
            
            return section

        }, configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
