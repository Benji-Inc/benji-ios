//
//  new_ConversationCollectionViewLayout.swift
//  new_ConversationCollectionViewLayout
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationCollectionViewLayout: UICollectionViewCompositionalLayout {

    init() {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalWidth(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: 1)
        let section = NSCollectionLayoutSection(group: group)
        
        super.init(section: section)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
