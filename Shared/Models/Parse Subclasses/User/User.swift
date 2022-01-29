//
//  User.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery
import Combine

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
    case focusImage
    case quePosition
    case status
    case handle
    case connectionPreferences
    case focusStatus
}

enum UserStatus: String {
    case needsVerification // Has entered a phone number but not a verification code.
    case inactive // Has verified but has not completed required onboarding
    case waitlist // Has verified but has not being granted access to the full app
    case active // Has verified and fully onboardied. Has full access to the app
}

enum FocusStatus: String {
    case focused
    case available
    
    var image: UIImage {
        switch self {
        case .focused:
            return UIImage(systemName: "moon.zzz.fill")!
        case .available:
            return UIImage(systemName: "hand.wave.fill")!
        }
    }
}

final class User: PFUser {

    var phoneNumber: String? {
        get { return self.getObject(for: .phoneNumber) }
        set { self.setObject(for: .phoneNumber, with: newValue)}
    }

    var givenName: String {
        get { return self.getObject(for: .givenName) ?? String() }
        set { self.setObject(for: .givenName, with: newValue) }
    }

    var familyName: String {
        get { return self.getObject(for: .familyName) ?? String() }
        set { self.setObject(for: .familyName, with: newValue) }
    }

    var handle: String {
        get { return self.getObject(for: .handle) ?? String() }
        set { self.setObject(for: .handle, with: newValue) }
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
            return UserStatus(rawValue: string)
        }
        set { self.setObject(for: .status, with: newValue?.rawValue) }
    }

    var focusStatus: FocusStatus? {
        get {
            guard let string: String = self.getObject(for: .focusStatus) else { return nil }
            return FocusStatus(rawValue: string)
        }
        set {
            self.smallImage?.clearCachedDataInBackground()
            self.setObject(for: .focusStatus, with: newValue?.rawValue)
        }
    }

    var connectionPreferences: [ConnectionPreference] {
        return self.getObject(for: .connectionPreferences) ?? []
    }
}
