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
    
    init(with contact: CNContact,
         reservation: Reservation? = nil,
         highlightText: String?) {
        
        self.image = contact.image
        self.cnContact = contact
        self.pendingReservation = reservation
        let phone = contact.findBestPhoneNumber().phone?.stringValue ?? ""
        self.phoneNumber = PartialFormatter().formatPartial(phone)
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.highlightText = highlightText
    }
    
    init(with connection: Connection, highlightText: String?) {
        self.connection = connection
        self.userObjectId = connection.nonMeUser?.userObjectId
        /// We may not have a user data at this point. 
        self.givenName = ""
        self.familyName = ""
        self.highlightText = highlightText
    }
}
