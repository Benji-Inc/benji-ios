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
        config.scrollDirection = .vertical

        super.init(sectionProvider: { sectionIndex, environment in
            let group
            = NSCollectionLayoutGroup(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(100),
                                                                         heightDimension: .absolute(100)))
            return NSCollectionLayoutSection(group: group)
        },
                   configuration: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
