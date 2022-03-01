//
//  ChatUser+Avatar.swift
//  ChatUser+Avatar
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatUser: PersonType {

    var parseUser: User? {
        return PeopleStore.shared.users.first { user in
            return user.objectId == self.personId
        }
    }

    var personId: String {
        return self.id
    }

    var givenName: String {
        return self.parseUser?.givenName ?? String()
    }

    var familyName: String {
        return self.parseUser?.familyName ?? String()
    }

    var handle: String {
        return self.parseUser?.handle ?? String()
    }

    var focusStatus: FocusStatus? {
        #warning("Get the focus status off the corresponding user?")
        return nil
    }

    var image: UIImage? {
        return self.parseUser?.image
    }

    var url: URL? {
        return self.parseUser?.url
    }
}
