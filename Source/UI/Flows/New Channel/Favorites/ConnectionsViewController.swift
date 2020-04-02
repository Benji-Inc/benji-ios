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
                let items = connections.filter { (connection) -> Bool in
                    return connection.status == .accepted
                }

                var users: [User] = []

                items.forEach { (connection) in
                    if let user = connection.nonMeUser {
                        users.append(user)
                    }
                }

                self.collectionViewManager.set(newItems: users)
        }

        self.collectionViewManager.allowMultipleSelection = true 
    }

    func getHeight(for width: CGFloat) -> CGFloat {
        return .zero
    }

    func getWidth(for height: CGFloat) -> CGFloat {
        return .zero
    }
}
