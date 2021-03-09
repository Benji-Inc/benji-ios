//
//  MeditationPost.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MeditationPost: SystemPost {

    init() {
        let type = PostType.meditation
        super.init(author: User.current()!,
                   body: "Take a minute to focus on your breathing, and think about others you care about.",
                   triggerDate: nil,
                   expirationDate: nil,
                   type: type,
                   file: nil,
                   attributes: nil,
                   priority: type.defaultPriority,
                   duration: type.defaultDuration)
    }
}
