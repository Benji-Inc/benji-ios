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

    var userObjectID: String? {
        return self.cnContact.userObjectID
    }

    var image: UIImage? {
        return self.cnContact.image
    }

    private let cnContact: CNContact
    private let pendingReservation: Reservation?
    private let phoneNumber: String?

    init(with contact: CNContact, reservation: Reservation? = nil) {
        self.cnContact = contact
        self.pendingReservation = reservation
        let phone = contact.findBestPhoneNumber().phone?.stringValue ?? ""
        self.phoneNumber = PartialFormatter().formatPartial(phone)
    }
}
