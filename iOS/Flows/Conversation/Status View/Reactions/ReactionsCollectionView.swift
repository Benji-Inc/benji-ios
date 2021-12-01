//
//  ReactionsCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReactionsCollectionView: CollectionView {

    init() {
        super.init(layout: ReactionsCollectionViewLayout())
        self.animationView.isHidden = true 
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
