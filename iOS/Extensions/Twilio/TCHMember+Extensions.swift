//
//  TCHMember+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 9/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import Combine

extension TCHMember: Avatar {

    var givenName: String {
        return String()
    }

    var familyName: String {
        return String()
    }

    var handle: String? {
        return nil
    }

    var image: UIImage? {
        return nil
    }

    var userObjectID: String? {
        return self.identity
    }
}

extension TCHMember {
    func getMemberAsUser() -> Future<User, Error> {
        return User.localThenNetworkQuery(for: self.identity!)
    }
}

