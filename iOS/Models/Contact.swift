//
//  Contact.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts
import PhoneNumberKit

struct Contact: Avatar, Hashable {

    var givenName: String {
        return self.cnContact.givenName
    }

    var familyName: String {
        return self.cnContact.familyName
    }

    var handle: String {
        return self.cnContact.handle
    }

    var userObjectId: String? {
        return self.cnContact.userObjectId
    }

    var image: UIImage? {
        return self.cnContact.image
    }

    let cnContact: CNContact
    let pendingReservation: Reservation?
    let phoneNumber: String

    init(with contact: CNContact, reservation: Reservation? = nil) {
        self.cnContact = contact
        self.pendingReservation = reservation
        let phone = contact.findBestPhoneNumber().phone?.stringValue ?? ""
        self.phoneNumber = PartialFormatter().formatPartial(phone) 
    }
}
