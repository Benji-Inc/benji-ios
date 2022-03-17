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
    
    static func create(with type: LocalAchievementType) async {
        guard let allTypes = try? await AchievementType.fetchAll(), let selectedType = allTypes.first(where: { t in
            return t.type == type.rawValue
        }) else { return }
        
        if selectedType.isRepeatable {
            await self.createAchievement(with: selectedType)
        } else {
            
            
        }
        
        // Get existing achievements
        // Filter by type
        
    }
    
    private static func createAchievement(with type: AchievementType) async {
//        
//        let transaction = Transaction()
//        tra
        // If type is not unique, create transaction with type data
        // Then create achievement with transaction and type.
    }
}
