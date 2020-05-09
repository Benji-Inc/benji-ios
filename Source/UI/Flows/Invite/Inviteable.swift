//
//  Inviteable.swift
//  Benji
//
//  Created by Benji Dodgson on 2/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

enum Inviteable: ManageableCellItem {
    case contact(CNContact, Connection.Status)
    case connection(Connection)

    var id: String {
        switch self {
        case .contact(let contact, _):
            return contact.identifier
        case .connection(let connection):
            return connection.objectId!
        }
    }
}

extension Inviteable: Avatar {

    var givenName: String {
        switch self {
        case .contact(let contact, _):
            return contact.givenName
        case .connection(let connection):
            return connection.nonMeUser?.givenName ?? String()
        }
    }

    var familyName: String {
        switch self {
        case .contact(let contact, _):
            return contact.familyName
        case .connection(let connection):
            return connection.nonMeUser?.familyName ?? String()
        }
    }

    var fullName: String {
        return self.givenName + " " + self.familyName
    }

    var userObjectID: String? {
        switch self {
        case .contact(_, _):
            return nil
        case .connection(let connection):
            return connection.nonMeUser?.objectId
        }
    }

    var image: UIImage? {
        switch self {
        case .contact(let contact, _):
            return contact.image
        case .connection(let connection):
            return connection.nonMeUser?.image
        }
    }

    var phoneNumber: String {
        switch self {
        case .contact(let contact, _):
            return String(optional: contact.primaryPhoneNumber)
        case .connection(let connection):
            return String(optional: connection.nonMeUser?.phoneNumber)
        }
    }
}
