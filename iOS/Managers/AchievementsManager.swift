//
//  AchievementsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AchievementsManager {
    
    enum LocalAchievementType: String {
        case sendInvite = "INVITE_SENT"
        case firstMessage = "FIRST_MESSAGE"
        case firstUnreadMessage = "FIRST_UNREAD_MESSAGE"
        case groupOfPlus = "GROUP_OF_PLUS"
        case firstGroup = "FIRST_GROUP"
        case firstFeeling = "FIRST_FEELING"
    }
    
    static let shared = AchievementsManager()
    
    private(set) var achievements: [Achievement] = []
    private(set) var types: [AchievementType] = []
    
    private var identifiers = Set<String>()
    
    init() {
        Task {
            try await self.fetchAll()
        }
    }
    
    private func fetchAll() async throws {
        if let types = try? await AchievementType.fetchAll() {
            self.types = types
        }
        
        if let achievements = try? await Achievement.fetchAll() {
            await achievements.asyncForEach { achievement in
                _ = try? await achievement.retrieveDataIfNeeded()
            }
            
            self.achievements = achievements
        }
    }
    
    func createIfNeeded(with type: LocalAchievementType, identifier: String) async {
        let id = type.rawValue + identifier
        guard !self.identifiers.contains(id) else { return }
        self.identifiers.insert(id)
        
        guard let selectedType = self.types.first(where: { t in
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
            AnalyticsManager.shared.trackEvent(type: .achievementCreated, properties: ["value": selectedType.type!])
        }
    }
    
    private func createAchievement(with type: AchievementType) async -> Achievement? {
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
