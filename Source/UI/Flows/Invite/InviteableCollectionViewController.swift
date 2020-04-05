//
//  InvitesCollectionViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 4/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InviteableCollectionViewController: CollectionViewController<InviteableCell, InviteableCollectionViewManger> {

    init() {
        super.init(with: InviteableCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
