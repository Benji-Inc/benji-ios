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
        
        var achievement: Achievement?
        if selectedType.isRepeatable {
            achievement = await self.createAchievement(with: selectedType)
        } else if let query = Achievement.query() {
            query.whereKey("type", equalTo: selectedType)
            if let _ = try? await query.firstObjectInBackground() {
                //If one exists do nothing.
            } else {
                //Otherwise create one.
                achievement = await self.createAchievement(with: selectedType)
            }            
        }
        
        if let value = achievement {
            await ToastScheduler.shared.schedule(toastType: .achievement(value))
        }
    }
    
    private static func createAchievement(with type: AchievementType) async -> Achievement? {
        guard let transaction = try? await Transaction.createTransaction(from: type) else { return nil }
        
        let achievement = Achievement()
        achievement.type = type
        achievement.amount = Double(type.bounty)
        achievement.transaction = transaction
        
        guard let saved = try? await achievement.saveToServer() else { return achievement }
        
        transaction.achievement = saved
        
        _ = try? await transaction.saveToServer()
        
        return achievement
    }
}
