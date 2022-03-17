//
//  Achievement+Create.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum LocalAchievementType: String {
    case sendInvite = "INVITE_SENT"
    case firstMessage = "FIRST_MESSAGE"
    case firstUnreadMessage = "FIRST_UNREAD_MESSAGE"
    case groupOfPlus = "GROUP_OF_PLUS"
    case firstGroup = "FIRST_GROUP"
    case firstFeeling = "FIRST_FEELING"
}

extension Achievement {
    
    func create(with type: LocalAchievementType) async {
        // Get existing achievements
        // Filter by type
        // If type is not unique, create transaction with type data
        // Then create achievement with transaction and type. 
    }
}
