//
//  PendingInviteViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 2/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import TMROFutures

class PendingCollectionViewController: CollectionViewController<PendingInviteCell, PendingCollectionViewManager>, Sizeable  {

    init() {
        let collectionView = PendingCollectionView()
        super.init(with: collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadConnections() {
        GetAllConnections(direction: .all)
            .makeRequest()
            .observeValue(with: { (connections) in
                let items = connections.map { (connection) -> Inviteable in
                    return .connection(connection)
                }

                self.collectionViewManager.set(newItems: items)
            })
    }
}
