//
//  NoticeCollectionView.swift
//  Ours
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class NoticeCollectionView: CollectionView {
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(layout: UICollectionViewLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.isPagingEnabled = true
        self.showsHorizontalScrollIndicator = false
    }
}
