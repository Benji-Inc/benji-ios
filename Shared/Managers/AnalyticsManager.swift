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
        case finishedOnboarding
    }
    
    init() {
        if isRelease {
            let configuration = PHGPostHogConfiguration(apiKey: "phc_nTIZgY0M0QgX0QB14Ux428lvGVnUeddJCqEFEo4vt9n",
                                                        host: "https://app.posthog.com")

            configuration.captureApplicationLifecycleEvents = true; // Record certain application events automatically!
            PHGPostHog.setup(with: configuration)
        }
    }
    
    func trackEvent(type: EventType,  properties: [String: Any]? = nil) {
        PHGPostHog.shared()?.capture(type.rawValue, properties: properties)
    }
}
