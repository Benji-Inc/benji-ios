//
//  FavoritesViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 9/8/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

class ConnectionsViewController: OrbCollectionViewController, Sizeable {

    override func initializeViews() {
        super.initializeViews()

        GetAllConnections().makeRequest()
            .observeValue { (connections) in
                let accepted = connections.filter { (connection) -> Bool in
                    return connection.status == .accepted
                }
                self.setItems(from: accepted)
        }

        self.collectionViewManager.allowMultipleSelection = true 
    }

    private func setItems(from connections: [Connection]) {

//        let orbItems = connections.map { (connection) in
//            return OrbCellItem(id: String(optional: connection.objectId),
//                               avatar: AnyHashableDisplayable(connection.to!getConnectionsgetConnections))
//        }
//
//        self.collectionViewManager.set(newItems: orbItems)
    }

    func getHeight(for width: CGFloat) -> CGFloat {
        return .zero
    }

    func getWidth(for height: CGFloat) -> CGFloat {
        return .zero
    }
}
