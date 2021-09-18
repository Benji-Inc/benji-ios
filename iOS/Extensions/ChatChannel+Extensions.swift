//
//  ChatChannel+Extensions.swift
//  ChatChannel+Extensions
//
//  Created by Benji Dodgson on 9/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatChannel {

    var isFromCurrentUser: Bool {
        return self.createdBy?.userObjectID == User.current()?.objectId
    }
}
