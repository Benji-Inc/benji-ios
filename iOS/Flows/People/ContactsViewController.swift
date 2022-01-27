//
//  ContactsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

class ContactsViewController: PeopleViewController {

    init() {
        super.init(includeConnections: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(collectionView: UICollectionView) {
        fatalError("init(collectionView:) has not been implemented")
    }

    override func getButtonTitle() -> Localized {
        return "Invite \(self.selectedItems.count)"
    }
}
