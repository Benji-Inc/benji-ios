//
//  InvitesCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 4/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InvitesCollectionView: CollectionView {

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        super.init(layout: flowLayout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initialize() {
        super.initialize()

        self.register(PendingConnectionCell.self)
        self.register(ContactCell.self)
        self.register(InviteSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
    }
}
