//
//  Achievement.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum AchievementKey: String {
    case type
    case attributes
    case amount
}

final class Achievement: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var type: AchievementType? {
        get {
            guard let value: String = self.getObject(for: .type), let t = AchievementType(rawValue: value) else { return nil }
            return t
        }
    }

    var attributes: [String: AnyHashable]? {
        get { self.getObject(for: .attributes) }
    }

    var amount: Double? {
        get { self.getObject(for: .amount) }
    }
}

extension Achievement: Objectable {
    typealias KeyType = AchievementKey

    func getObject<Type>(for key: AchievementKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: AchievementKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: AchievementKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}

enum AchievementType: String, CaseIterable {
    
    case joinJibber = "JOIN_JIBBER"
    case inviteSent = "INVITE_SENT"
    case firstMessage = "FIRST_MESSAGE"
    case firstFeeling = "FIRST_FEELING"
    case firstUnreadMessage = "FIRST_UNREAD_MESSAGE"
    case firstGroup = "FIRST_GROUP"
    case groupOfThreePlus = "GROUP_OF_PLUS"
    case bugBounty = "BUG_BOUNTY"
    case featureRequest = "FEATURE_REQUEST"
    case firstTenK = "FIRST_10K"
    case investor = "INVESTOR"
    
    var bounty: Double {
        switch self {
        case .joinJibber:
            return 10
        case .inviteSent:
            return 5
        case .firstMessage:
            return 1
        case .firstFeeling:
            return 1
        case .firstUnreadMessage:
            return 1
        case .firstGroup:
            return 2
        case .groupOfThreePlus:
            return 2
        case .bugBounty:
            return 1
        case .featureRequest:
            return 1
        case .firstTenK:
            return 10
        case .investor:
            return 100
        }
    }
    
    var title: String {
        switch self {
        case .joinJibber:
            return "Join Jibber"
        case .inviteSent:
            return "Send Invite"
        case .firstMessage:
            return "First Message"
        case .firstFeeling:
            return "First Feeling"
        case .firstUnreadMessage:
            return "First Read Message"
        case .firstGroup:
            return "First Group"
        case .groupOfThreePlus:
            return "First Group 3+"
        case .bugBounty:
            return "Bug Bounty"
        case .featureRequest:
            return "Feature Request"
        case .firstTenK:
            return "First 10,000"
        case .investor:
            return "Invest in Jibber"
        }
    }
    
    var description: String {
        switch self {
        case .joinJibber:
            return "Earned for successfully joining Jibber."
        case .inviteSent:
            return "Earned for every invite sent."
        case .firstMessage:
            return "Earned for sending your first message."
        case .firstFeeling:
            return "Earned for sending your first feeling."
        case .firstUnreadMessage:
            return "Earned for reading your first message."
        case .firstGroup:
            return "Earned for creating your first group."
        case .groupOfThreePlus:
            return "Earned for joining your first group of 3+."
        case .bugBounty:
            return "Earned for reporting a bug. Just take a screen shot, and choose the option to send to Test Flight."
        case .featureRequest:
            return "Earned for sharing a feature request."
        case .firstTenK:
            return "Earned for being one of the first 10k users on Jibber."
        case .investor:
            return "Earned for making an investment in Jibber. Add your email to learn more."
        }
    }
    
    var isAvailable: Bool {
        return false
    }
}

