//
//  User.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift
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
    case active // Has completed onboarding and has full access to the app
    case waitlist // Has verified phone number and is waiting for access to the app
    case inactive // Has been given access to the full app but has not completed onboarding
    case needsVerification // Has entered a phone number but not a verification code. 
}

enum FocusStatus: String {
    case focused
    case available
}

struct User: ParseUser {
    
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    //: These are required by `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?
    
    var phoneNumber: String?
    var givenName: String
    var familyName: String
    var handle: String
    var smallImage: ParseFile?
    var focusImage: ParseFile?
    var quePosition: Int?
//    var status: UserStatus?
//    var focusStatus: FocusStatus?
}
