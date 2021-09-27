//
//  ContactsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

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
    
    override func getHeaderTitle() -> Localized {
        return "Send invites"
    }

    override func getHeaderDescription() -> Localized {
        return "Select your contacts below to send them an inivte."
    }

    override func getButtonTitle() -> Localized {
        return "Invite \(self.selectedItems.count)"
    }
}
