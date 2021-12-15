//
//  SystemAvatar.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

struct SystemAvatar: Avatar, Hashable {
    var userObjectId: String?
    var givenName: String
    var familyName: String
    var image: UIImage?
    var handle: String
}
