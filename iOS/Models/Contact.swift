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

struct Person: Avatar, Hashable, Comparable {
    
    static func < (lhs: Person, rhs: Person) -> Bool {
        if let _ = lhs.connection,
           let _ = rhs.connection {
            return lhs.familyName < rhs.familyName
        } else if let _ = lhs.cnContact,
                    let _ = rhs.cnContact {
            return lhs.familyName < rhs.familyName
        } else {
            return false 
        }
    }
    
    var identifier: String {
        return self.connection?.objectId ?? self.cnContact?.identifier ?? ""
    }
    
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
    
    var isSelected: Bool
    
    init(withContact contact: CNContact, isSelected: Bool = false) {
        self.image = contact.image
        self.cnContact = contact
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        self.isSelected = isSelected
    }
    
    init(withConnection connection: Connection, isSelected: Bool = false) {
        self.connection = connection
        self.userObjectId = connection.nonMeUser?.userObjectId
        self.isSelected = isSelected
        /// We may not have a user data at this point.
        
        if let user = connection.nonMeUser, user.isDataAvailable {
            self.givenName = user.givenName
            self.familyName = user.familyName
        } else {
            self.givenName = ""
            self.familyName = ""
        }
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
