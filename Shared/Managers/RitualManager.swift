//
//  RitualManager.swift
//  Benji
//
//  Created by Martin Young on 8/13/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications
import Combine

class RitualManager {

    let messageReminderID = "MessageReminderID"
    let lastChanceReminderID = "LastChanceReminderID"

    static let shared = RitualManager()
    private var cancellables = Set<AnyCancellable>()

    func getNotifications() -> Future<[UNNotificationRequest], Never> {
        return Future { promise in
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.getPendingNotificationRequests { (requests) in
                let ritualRequests = requests.filter { (request) -> Bool in
                    return request.identifier.contains(self.messageReminderID)
                }
                promise(.success(ritualRequests))
            }
        }
    }

    func scheduleNotification(for ritual: Ritual) {

        let identifier = self.messageReminderID + ritual.timeDescription

        // Replace any previous notifications
        UserNotificationManager.shared.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Feed Unlocked"
        content.body = "Your daily feed is unlocked for the next hour."
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "ritual"

        //        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let trigger = UNCalendarNotificationTrigger(dateMatching: ritual.timeComponents,
                                                    repeats: true)

        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)

        UserNotificationManager.shared.schedule(note: request)
            .mainSink(receiveValue: { (_) in
                self.scheduleLastChanceNotification(for: ritual)
            }).store(in: &self.cancellables)
    }

    func scheduleLastChanceNotification(for ritual: Ritual) {

        let identifier = self.lastChanceReminderID

        let content = UNMutableNotificationContent()
        content.title = "Last Chance"
        content.body = "You have 10 mins left to check your feed for the day."
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "ritual"

        var lastChanceTime: DateComponents = ritual.timeComponents
        if let minutes = ritual.timeComponents.minute {
            var min = minutes + 50
            var hour = ritual.timeComponents.hour ?? 0
            if min > 60 {
                min -= 60
                hour += 1
            }
            lastChanceTime.minute = min
            lastChanceTime.hour = hour
        } else {
            lastChanceTime.minute = 50
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: lastChanceTime,
                                                    repeats: true)

        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)

        UserNotificationManager.shared.schedule(note: request)
            .mainSink(receiveValue: { (_) in }).store(in: &self.cancellables)
    }
}
