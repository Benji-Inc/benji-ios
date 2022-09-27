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
 //        Get current moment reminders
        let current = await self.getPendingRequests().filter { request in
            return request.identifier.contains("moment")
        }.count

        let max = 7
        let start = clamp(current, min: 0, max: max)
        
        guard start < max else { return }

        // Ensure reminders are at least 7 days out
        await (start...max).asyncForEach({ index in

            // Get random triggers between 9am and 9pm
            if let components = self.getRandomTrigger(for: index) {
                let trigger = UNCalendarNotificationTrigger.init(dateMatching: components, repeats: false)

                let content = UNMutableNotificationContent()
                content.title = "Record a Moment 🤳"
                content.body = "And see Moments from others 👀"
                content.interruptionLevel = .timeSensitive
                content.setData(value: "capture", for: .target)
                let identifier = "moment" + UUID().uuidString

                // Schedule remaining reminders
                await self.scheduleNotification(with: content, identifier: identifier, trigger: trigger)
            }
        })
    }

    private func getRandomTrigger(for day: Int) -> DateComponents? {
        let today = Date.today
        guard let new = today.add(component: .day, amount: day) else { return nil }
        
        var components = DateComponents()
        components.minute = Int.random(in: 0...60)
        components.hour = Int.random(in: 9...18)
        components.day = new.day
        components.month = new.month
        components.year = new.year
        
        return components
    }
}
