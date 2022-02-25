//
//  User+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 11/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

extension User: Avatar {

    var userObjectId: String? {
        self.objectId
    }

    var image: UIImage? {
        return nil
    }
    
    static var isOnWaitlist: Bool {
        guard let current = User.current() else { return false }
        return current.status == .waitlist
    }

    var isOnboarded: Bool {
        if self.fullName.isEmpty {
            return false
        } else if self.smallImage.isNil {
            /// Do not require simulators to have image. They can't take one.
            #if targetEnvironment(simulator)
            return true
            #else
            return false
            #endif
        }

        return true 
    }

    var isCurrentUser: Bool {
        return self.objectId == User.current()?.objectId
    }
    
    func getLocalTime() -> String {
        let timeZone: TimeZone?
        if self.isCurrentUser {
            timeZone = TimeZone.current
        } else {
            let timeZoneId = self.timeZone
            timeZone = TimeZone.init(identifier: timeZoneId)
        }
        
        let formatter = Date.hourMinuteTimeOfDay
        formatter.timeZone = timeZone
        let localTime = formatter.string(from: Date())
        return localTime.isEmpty ? "Unknown" : localTime
    }
}

extension User {
    
    func formatName(from text: String) {
        let components = text.components(separatedBy: " ").filter { (component) -> Bool in
            return !component.isEmpty
        }
        if let first = components.first {
            self.givenName = first
        }
        if let last = components.last {
            self.familyName = last
        }
    }
}
