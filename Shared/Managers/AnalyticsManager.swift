//
//  AnalyticsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import PostHog

class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    
    enum EventType: String {
        case finalizedOnboarding = "ONBOARDING_FINALIZED"
        case onboardingBeginTapped = "ONBOARDING_BEGIN_TAPPED"
        case onboardingRSVPTapped = "ONBOARDING_RSVP_TAPPED"
        case emotionSelected = "EMOTION_SELECTED"
        case expressionSelected = "EXPRESSION_SELECTED"
        case expressionMade = "EXPRESSION_MADE"
        case deliveryTypeSelected = "DELIVERY_TYPE_SELECTED"
        case messageSent = "MESSAGE_SENT"
        case replySent = "REPLY_SENT"
        case suggestionSelected = "SUGGESTION_SELECTED"
        case inviteSent = "INVITE_SENT"
        case conversationCreated = "CONVERSATION_CREATED"
        case contextCueCreated = "CONTEXT_CUE_CREATED"
        case achievementCreated = "ACHIEVEMENT_CREATED"
    }
    
    init() {
        if isRelease {
            let configuration = PHGPostHogConfiguration(apiKey: "phc_vOn43aOVi1hlzaOpFZqDe4BrKmMgVcz4wtW0LghCyYP",
                                                        host: "https://app.posthog.com")
            
            configuration.captureApplicationLifecycleEvents = true; // Record certain application events automatically!
            PHGPostHog.setup(with: configuration)
        }
    }
    
    func trackEvent(type: EventType, properties: [String: Any]? = nil) {
        guard isRelease else { return }
        PHGPostHog.shared()?.capture(type.rawValue, properties: properties)
    }
    
    func trackStreen(type: String, properties: [String: Any]? = nil) {
        guard isRelease else { return }
        PHGPostHog.shared()?.screen(type, properties: properties)
    }
}
