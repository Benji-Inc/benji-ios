//
//  NSUserActivity+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension NSUserActivity {
    
    var launchActivity: LaunchActivity? {
        
        if self.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = self.webpageURL,
           let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) {
            guard let path = components.path else { return nil }
            switch path {
            case "/onboarding":
                if let item = components.queryItems?.first,
                   let phoneNumber = item.value {
                    return .onboarding(phoneNumber: phoneNumber)
                }
            case "/reservation":
                if let item = components.queryItems?.first,
                   let reservationId = item.value {
                    return .reservation(reservationId: reservationId)
                }
            case "/pass":
                if let item = components.queryItems?.first,
                   let passId = item.value {
                    return .pass(passId: passId)
                }
            case "/moment":
                if let item = components.queryItems?.first,
                   let momentId = item.value {
                    var object = DeepLinkObject(target: .moment)
                    object.momentId = momentId
                    return .deepLink(object)
                }
            default:
                return nil
            }
        }
        return nil
    }
}
