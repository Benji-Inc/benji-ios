//
//  ChannelsCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelsCollectionView: PagingCollectionView {

    init() {
        let layout = PagingCollectionViewFlowLayout(portraitRatio: 0.2, landscapeRatio: 0.1)
        layout.sideItemScale = 0.95
        layout.scrollDirection = .horizontal

        super.init(pagingLayout: layout)

        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
