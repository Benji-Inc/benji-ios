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
import Parse

struct Person: PersonType, Hashable, Comparable {

    static func < (lhs: Person, rhs: Person) -> Bool {
        if lhs.connection.exists && rhs.connection.exists {
            return lhs.familyName < rhs.familyName
        } else if lhs.cnContact.exists && rhs.cnContact.exists {
            return lhs.familyName < rhs.familyName
        } else {
            return false 
        }
    }

    var personId: String
    var phoneNumber: String?
    
    var familyName: String
    var givenName: String
    var handle: String {
        return ""
    }
    var focusStatus: FocusStatus? {
        return nil
    }

    var image: UIImage?
    
    var highlightText: String?


    var connection: Connection?

    var cnContact: CNContact?
    
    var isSelected: Bool
    
    init(withContact contact: CNContact, isSelected: Bool = false) {
        self.personId = contact.personId
        self.phoneNumber = contact.phoneNumber

        self.image = contact.image
        self.cnContact = contact
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.isSelected = isSelected
    }
    
    init(person: PersonType, connection: Connection?, isSelected: Bool = false) {
        self.personId = person.personId
        self.phoneNumber = person.phoneNumber
        self.connection = connection
        self.isSelected = isSelected

        // We may not have user data at this point.
        self.givenName = person.givenName
        self.familyName = person.familyName
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
