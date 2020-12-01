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
        layout.scrollDirection = .vertical
        super.init(pagingLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.register(ReservationsFooter.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
    }
}
