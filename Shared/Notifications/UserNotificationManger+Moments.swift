//
//  UserNotificationManger+Moments.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications

extension UserNotificationManager {
    
    func scheduleMomentReminders() async {
        
        // Get current moment reminders
        var current = await self.getPendingRequests().filter { request in
            return request.identifier.contains("moment")
        }.count

        current = clamp(current, min: 0)

        // Ensure reminders are at least 7 days out
        await (current - 1...7).asyncForEach({ index in

            // Get random triggers between 9am and 9pm
            let components = self.getRandomTrigger(for: index)
            let trigger = UNCalendarNotificationTrigger.init(dateMatching: components, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Record a moment 🤳"
            content.body = "Record now and see ones from family & friends. 🤗"
            content.interruptionLevel = .timeSensitive
            content.setData(value: "capture", for: .target)
            let identifier = "moment" + UUID().uuidString

            // Schedule remaining reminders
            await self.scheduleNotification(with: content, identifier: identifier, trigger: trigger)
        })
    }
    
    private func getRandomTrigger(for day: Int) -> DateComponents {
        let today = Date.today
        
        var components = DateComponents()
        components.minute = Int.random(in: 0...60)
        components.hour = Int.random(in: 9...18)
        components.day = today.day + day 
        components.month = today.month
        components.year = today.year
        
        return components
    }
}
