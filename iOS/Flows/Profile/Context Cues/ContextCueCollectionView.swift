//
//  ContextCueCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCueCollectionView: CollectionView {
    
    init() {
        super.init(layout: ContextCueCollectionViewLayout())
        self.semanticContentAttribute = .forceRightToLeft
        self.showsHorizontalScrollIndicator = false
        self.clipsToBounds = false
        self.decelerationRate = .fast
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
