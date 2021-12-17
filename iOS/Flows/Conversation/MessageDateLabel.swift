//
//  ConversationHeaderDateLabel.swift
//  Benji
//
//  Created by Benji Dodgson on 7/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDateLabel: ThemeLabel {

    init() {
        super.init(font: .small)

        self.textAlignment = .center
        self.numberOfLines = 1
        self.setFont(.small)
        self.setTextColor(.lightGray)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(date: Date?) {
        guard let date = date else {
            self.text = nil
            return
        }

        self.text = self.getString(for: date)
    }

    func getString(for date: Date) -> String {
        let now = Date()

        if date.isSameDay(as: now) {
            if let lessThanMinAgo = now.subtract(component: .minute, amount: 1), lessThanMinAgo < date {
                return "Now"
            } else if let tenMinutesAgo = now.subtract(component: .minute, amount: 10), tenMinutesAgo < date {
                let formatter = DateFormatter()
                formatter.dateFormat = "mm"
                return formatter.string(from: date) + " mins ago"
            } else {
                return Date.hourMinuteTimeOfDay.string(from: date)
            }
        } else if let yesterday = now.subtract(component: .day, amount: 1), date.isSameDay(as: yesterday) {
            return "Yesterday"
        } else if let weekAgo = now.subtract(component: .weekOfMonth, amount: 1), date.isBetween(now, and: weekAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return "Last " + formatter.string(from: date)
        } else if let twoWeeksAgo = now.subtract(component: .weekOfMonth, amount: 2), date.isBetween(now, and: twoWeeksAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return "Last week " + formatter.string(from: date)
        } else if let yearAgo = now.subtract(component: .year, amount: 1), date.isBetween(now, and: yearAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yy"
            return formatter.string(from: date)
        }
    }
}
