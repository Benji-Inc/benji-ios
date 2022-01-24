//
//  ContactCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import Contacts
import PhoneNumberKit

class ContactCell: PersonCell, ManageableCell {
    typealias ItemType = Contact

    var currentItem: Contact?

    func configure(with item: Contact) {
        self.titleLabel.setText(item.fullName)
        self.layoutNow()
    }
}
