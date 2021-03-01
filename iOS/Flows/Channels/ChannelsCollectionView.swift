//
//  ChannelsCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie

class ChannelsCollectionView: CollectionView {

    init(with layout: UICollectionViewCompositionalLayout) {
        super.init(layout: layout)
        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
