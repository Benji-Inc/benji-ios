//
//  NotificationPermissionsPost.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NotificationPermissionsPost: SystemPost {

    init() {
        let type = PostType.notificationPermissions
        super.init(author: User.current()!,
                   body: "Notifications are only sent for important messages and daily ritual remiders. Nothing else.",
                   triggerDate: nil,
                   expirationDate: nil,
                   type: type,
                   file: nil,
                   attributes: nil,
                   priority: type.defaultPriority,
                   duration: type.defaultDuration)
    }
}
