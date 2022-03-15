//
//  WelcomeCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A collection view to display a the Welcome Conversation using the Time Machine layout.
class WelcomeCollectionView: CollectionView {

    var timeMachineLayout: MessagesTimeMachineCollectionViewLayout {
        return self.collectionViewLayout as! MessagesTimeMachineCollectionViewLayout
    }

    init() {
        let layout = MessagesTimeMachineCollectionViewLayout()
        super.init(layout: layout)
        self.showsVerticalScrollIndicator = false
        self.keyboardDismissMode = .interactive
        self.automaticallyAdjustsScrollIndicatorInsets = true
        self.decelerationRate = .fast
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
