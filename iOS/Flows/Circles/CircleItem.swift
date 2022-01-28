//
//  CircleItem.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

struct CircleItem: Avatar, Hashable {
    
    var givenName: String {
        if let user = self.user {
            return user.givenName
        } else if let contact = self.contact {
            return contact.givenName
        } else {
            return ""
        }
    }
    
    var familyName: String {
        if let user = self.user {
            return user.familyName
        } else if let contact = self.contact {
            return contact.familyName
        } else {
            return ""
        }
    }
    
    var handle: String {
        return self.user?.handle ?? ""
    }
    
    var userObjectId: String? {
        return self.user?.objectId ?? nil
    }
    
    var image: UIImage? {
        return self.user?.image
    }
    
    var position: Int 
    var user: User?
    var contact: CNContact?
    
    var canAdd: Bool {
        return self.user.isNil && self.contact.isNil 
    }
}
