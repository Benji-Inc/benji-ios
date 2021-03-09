//
//  ReservationPost.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationPost: SystemPost {

    init(with reservation: Reservation) {
        let type = PostType.inviteAsk
        let attributes = ["reservation": reservation]
        super.init(author: User.current()!,
                   body: "Who would you like to share Ours with?",
                   triggerDate: nil,
                   expirationDate: nil,
                   type: type,
                   file: nil,
                   attributes: attributes,
                   priority: type.defaultPriority,
                   duration: type.defaultDuration)
    }
}
