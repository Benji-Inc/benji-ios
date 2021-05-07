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

    enum State {
        case initial
        case noRitual
        case lessThanAnHourAway(Date)
        case feedAvailable
        case lessThanHourAfter(Date)
        case moreThanHourAfter(Date)
    }

    @Published var state: State = .initial

    var currentTriggerDate: Date? {
        return UserDefaults.standard.value(forKey: Ritual.currentKey) as? Date
    }

    init() {
        self.subscribeToUpdates()
        if let user = User.current() {
            self.determineState(for: user)
        }
    }

    private func subscribeToUpdates() {
        User.current()?.subscribe()
            .mainSink(receiveValue: { (event) in
                switch event {
                case .created(let u), .updated(let u), .entered(let u):
                    self.determineState(for: u)
                case .deleted(_):
                    self.state = .noRitual
                default:
                    break
                }
            }).store(in: &self.cancellables)
    }

    func determineState(for user: User) {
        if let ritual = user.ritual {
            ritual.retrieveDataFromServer()
                .mainSink { result in
                    switch result {
                    case .success(let r):
                        self.determineState(for: r)
                    case .error(_):
                        self.state = .noRitual
                    }
                }.store(in: &self.cancellables)
        } else {
            self.state = .noRitual
        }
    }

    private func determineState(for ritual: Ritual) {
        guard let triggerDate = ritual.date,
            self.currentTriggerDate != triggerDate,
            let anHourAfter = triggerDate.add(component: .hour, amount: 1),
            let anHourUntil = triggerDate.subtract(component: .hour, amount: 1) else { return }

        //Set the current trigger date so we dont reload for duplicates
        UserDefaults.standard.set(triggerDate, forKey: Ritual.currentKey)

        let now = Date()

        //If date is 1 hour or less away, show countDown
        if now.isBetween(anHourUntil, and: triggerDate) {
            self.state = .lessThanAnHourAway(triggerDate)

            //If date is less than an hour ahead of current date, show feed
        } else if now.isBetween(triggerDate, and: anHourAfter) {
            self.state = .feedAvailable

        //If date is 1 hour or more away, show "see you at (date)"
        } else if now.isBetween(Date().beginningOfDay, and: anHourUntil) {
            self.state = .lessThanHourAfter(triggerDate)
        } else {
            self.state = .moreThanHourAfter(triggerDate)
        }
    }

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

    func createRitual(for date: Date) -> Future<User, Error> {
        let ritual = User.current()?.ritual ?? Ritual()
        ritual.create(with: date)
        User.current()?.ritual = ritual
        self.scheduleNotification(for: ritual)
        return User.current()!.saveLocalThenServer()
    }

    func scheduleNotification(for ritual: Ritual) {

        let identifier = self.messageReminderID + ritual.timeDescription

        // Replace any previous notifications
        UserNotificationManager.shared.removeNonEssentialPendingNotifications()

        let content = UNMutableNotificationContent()
        content.title = "Feed Unlocked"
        content.body = "Your daily feed is unlocked for the next hour."
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "ritual"
        content.setData(value: DeepLinkTarget.feed.rawValue, for: .target)

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
        content.setData(value: DeepLinkTarget.feed.rawValue, for: .target)

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
