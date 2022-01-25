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

struct Person: Avatar, Hashable {
    
    var familyName: String
    var givenName: String
    var handle: String {
        return ""
    }
    
    var userObjectId: String?
    var image: UIImage?
    
    var highlightText: String?
    
    var connection: Connection?
    
    var cnContact: CNContact?
    var pendingReservation: Reservation?
    var phoneNumber: String?
    
    init(withContact contact: CNContact, reservation: Reservation? = nil) {
        self.image = contact.image
        self.cnContact = contact
        self.pendingReservation = reservation
        let phone = contact.findBestPhoneNumber().phone?.stringValue ?? ""
        self.phoneNumber = PartialFormatter().formatPartial(phone)
        self.givenName = contact.givenName
        self.familyName = contact.familyName
    }
    
    init(withConnection connection: Connection) {
        self.connection = connection
        self.userObjectId = connection.nonMeUser?.userObjectId
        /// We may not have a user data at this point. 
        self.givenName = ""
        self.familyName = ""
    }
    
    mutating func updateHighlight(text: String?) {
        self.highlightText = text
    }
    
    func contains(_ filter: String?) -> Bool {
        guard let filterText = filter else { return true }
        if filterText.isEmpty { return true }
        let lowercasedFilter = filterText.lowercased()
        return self.fullName.lowercased().contains(lowercasedFilter)
    }
}
