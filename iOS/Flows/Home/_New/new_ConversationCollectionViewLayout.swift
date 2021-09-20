//
//  new_ConversationCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class new_ConversationCollectionViewLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        self.scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
