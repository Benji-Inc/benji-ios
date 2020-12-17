//
//  User.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

enum ObjectKey: String {
    case objectId
    case createAt
    case updatedAt
}

enum UserKey: String {
    case email
    case phoneNumber
    case givenName
    case familyName
    case smallImage
    case routine
    case quePosition
    case status
}

enum UserStatus: String {
    case active // Has completed onboarding and has full access to the app
    case waitlist // Has verified phone number and is waiting for access to the app
    case inactive // Has been given access to the full app but has not completed onboarding
}

final class User: PFUser {

    var phoneNumber: String? {
        get { return self.getObject(for: .phoneNumber) }
        set { self.setObject(for: .phoneNumber, with: newValue)}
    }

    var givenName: String {
        get { return String(optional: self.getObject(for: .givenName)) }
        set { self.setObject(for: .givenName, with: newValue) }
    }

    var familyName: String {
        get { return String(optional: self.getObject(for: .familyName)) }
        set { self.setObject(for: .familyName, with: newValue) }
    }

    var routine: Routine? {
        get { return self.getObject(for: .routine) }
        set { self.setObject(for: .routine, with: newValue) }
    }

    var smallImage: PFFileObject? {
        get { return self.getObject(for: .smallImage) }
        set { self.setObject(for: .smallImage, with: newValue) }
    }

    var quePosition: Int? {
        get { return self.getObject(for: .quePosition) }
        set { self.setObject(for: .quePosition, with: newValue) }
    }

    var status: UserStatus? {
        get {
            guard let string: String = self.getObject(for: .status) else { return nil }
            return UserStatus.init(rawValue: string)
        }
        set { self.setObject(for: .status, with: newValue?.rawValue) }
    }
}
