//
//  AchievementsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/16/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseLiveQuery

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
    
    //private var identifiers = Set<String>()
    
    private var initializeTask: Task<Void, Error>?
    
    init() {
        Task {
            try await self.fetchAll()
        }
    }
    
    private func fetchAll() async throws {
        
        // If we already have an initialization task, wait for it to finish.
        if let initializeTask = self.initializeTask {
            try await initializeTask.value
            return
        }
        
        // Otherwise start a new initialization task and wait for it to finish.
        self.initializeTask = Task {
            if let types = try? await AchievementType.fetchAll() {
                self.types = types
            }
            
            if let achievements = try? await Achievement.fetchAll() {
                await achievements.asyncForEach { achievement in
                    _ = try? await achievement.retrieveDataIfNeeded()
                }
                
                self.achievements = achievements
            }
            
            self.subscribeToUpdates()
        }
    }
    
    private func subscribeToUpdates() {
        guard let query = Achievement.query() else { return }
        Client.shared.unsubscribe(query)
        
        query.includeKey("type")
        let subscription = Client.shared.subscribe(query)
        subscription.handleEvent { query, event in
            switch event {
            case .updated(let object):
                guard let achievement = object as? Achievement,
                        !self.achievements.contains(achievement) else { return }
                
                Task {
                    await ToastScheduler.shared.schedule(toastType: .achievement(achievement))
                }
                self.achievements.append(achievement)
            default:
                break
            }
        }
    }
    
    func createIfNeeded(with type: LocalAchievementType, identifier: String) {
        
        let id = type.rawValue + identifier
        var current = UserDefaultsManager.getStrings(for: .localAchievements)
        guard !current.contains(id) else { return }
        
        current.append(id)
        UserDefaultsManager.update(key: .localAchievements, with: current)
        
        Task {
            
            // If we already have an initialization task, wait for it to finish.
            if let initializeTask = self.initializeTask {
                try await initializeTask.value
                return
            }
            
            await self.create(with: type)
        }
    }
    
    private func create(with type: LocalAchievementType) async {
        
        guard let selectedType = self.types.first(where: { t in
            return t.type == type.rawValue
        }) else { return }
        
        var achievement: Achievement?
        
        if selectedType.isRepeatable {
            achievement = await self.createAchievement(with: selectedType)
        } else if self.achievements.first(where: { achievement in
            return achievement.type == selectedType
        }).isNil {
            achievement = await self.createAchievement(with: selectedType)
        }
        
        if let _ = achievement {
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
