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

    var handle: String {
        return String()
    }

    var image: UIImage? {
        return nil
    }

    var userObjectID: String? {
        return self.identity
    }
}

extension TCHMember {

    func getMemberAsUser() async throws -> User {
        let user = try await User.localThenNetworkQuery(for: self.identity!)
        return user
    }
}

