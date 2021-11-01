//
//  ConversationHeaderDateLabel.swift
//  Benji
//
//  Created by Benji Dodgson on 7/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDateLabel: Label {

    private(set) var currentDate: Date?

    init() {
        super.init(font: .small)

        self.setText(" ")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(date: Date) {

        let attributed = AttributedString(self.getString(for: date),
                                          fontType: .small,
                                          color: .lightGray)
        self.set(attributed: attributed,
                 alignment: .center,
                 lineCount: 1,
                 stringCasing: .unchanged)

        self.currentDate = date
    }

    private func getString(for date: Date) -> String {

        let now = Date()

        if date.isSameDay(as: now) {
            return "Today"
        } else if let yesterday = now.subtract(component: .day, amount: 1), date.isSameDay(as: yesterday) {
            return "Yesterday"
        } else if let weekAgo = now.subtract(component: .weekOfMonth, amount: 1), date.isBetween(now, and: weekAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Last " + formatter.string(from: date)
        } else if let twoWeeksAgo = now.subtract(component: .weekOfMonth, amount: 2), date.isBetween(now, and: twoWeeksAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Last week " + formatter.string(from: date)
        } else if let yearAgo = now.subtract(component: .year, amount: 1), date.isBetween(now, and: yearAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}
