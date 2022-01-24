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

struct Person: Hashable {
    var fullName: String
    var highlightText: String?
    
    var cnContact: CNContact?
    var pendingReservation: Reservation?
    var phoneNumber: String?
    
    init(with contact: CNContact,
         reservation: Reservation? = nil,
         highlightText: String?) {
        
        self.cnContact = contact
        self.pendingReservation = reservation
        let phone = contact.findBestPhoneNumber().phone?.stringValue ?? ""
        self.phoneNumber = PartialFormatter().formatPartial(phone)
        self.fullName = contact.givenName + " " + contact.familyName
        self.highlightText = highlightText
    }
    
    init(with user: User, highlightText: String?) {
        self.fullName = user.fullName
        self.highlightText = highlightText
    }
}

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
