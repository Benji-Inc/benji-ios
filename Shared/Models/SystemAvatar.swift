//
//  SystemAvatar.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct SystemAvatar: PersonType, Hashable {

    var personId: String {
        return "system-avatar"
    }
    var givenName: String
    var familyName: String
    var handle: String
    var focusStatus: FocusStatus? {
        return nil
    }

    var phoneNumber: String?

    var image: UIImage?
    
    var updatedAt: Date? {
        return Date()
    }
}
