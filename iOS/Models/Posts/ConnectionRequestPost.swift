//
//  ConnectionRequestPost.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConnectionRequestPost: SystemPost {

    init(with connection: Connection) {
        let type = PostType.connectionRequest
        let attributes = ["connection": connection]
        super.init(author: User.current()!,
                   body: String(),
                   triggerDate: nil,
                   expirationDate: nil,
                   type: type,
                   file: nil,
                   attributes: attributes,
                   priority: type.defaultPriority,
                   duration: type.defaultDuration)
    }
}
