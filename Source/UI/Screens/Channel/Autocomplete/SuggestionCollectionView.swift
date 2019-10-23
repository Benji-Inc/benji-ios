//
//  AutocompleteCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 10/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class SuggestionCollectionView: CollectionView {

    init() {
        let flowLayout = SuggestionCollectionViewLayout()
        super.init(flowLayout: flowLayout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
