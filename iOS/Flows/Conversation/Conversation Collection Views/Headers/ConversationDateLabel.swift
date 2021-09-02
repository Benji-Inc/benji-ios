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
        
        if date.isSameDay(as: Date.today) {
            return "Today"
        }

        let stringDate = Date.monthAndDay.string(from: date)
        return stringDate
    }
}
