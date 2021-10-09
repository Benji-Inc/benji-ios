//
//  ConversationHeaderDateLabel.swift
//  Benji
//
//  Created by Benji Dodgson on 7/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationDateLabel: Label {

    init() {
        super.init(font: .smallBold)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeLabel() {
        super.initializeLabel()

        self.textAlignment = .right
    }

    func set(date: Date) {

        let attributed = AttributedString(self.getString(for: date),
                                          fontType: .smallBold,
                                          color: .background3)
        self.set(attributed: attributed,
                 alignment: .right,
                 lineCount: 1,
                 stringCasing: .uppercase)
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
            return "This " + formatter.string(from: date)
        } else if let twoWeeksAgo = now.subtract(component: .weekOfMonth, amount: 2), date.isBetween(now, and: twoWeeksAgo) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Last " + formatter.string(from: date)
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
