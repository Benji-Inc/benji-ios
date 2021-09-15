//
//  ChatUser+Avatar.swift
//  ChatUser+Avatar
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatUser: Avatar {

    var givenName: String {
        return self.name ?? String()
    }

    var familyName: String {
        return self.name ?? String()
    }

    var handle: String {
        return self.name ?? String()
    }

    var userObjectID: String? {
        return self.id
    }

    var image: UIImage? {
        return nil
    }

    var url: URL? {
        return self.imageURL
    }
}
