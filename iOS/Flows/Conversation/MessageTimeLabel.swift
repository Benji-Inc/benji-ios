//
//  ConversationTimeLabel.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageTimeLabel: Label {

    private(set) var currentDate: Date?

    init() {
        super.init(font: .small)

        self.setText(" ")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(date: Date) {

        let attributed = AttributedString(Date.hourMinuteTimeOfDay.string(from: date),
                                          fontType: .small,
                                          color: .lightGray)
        self.set(attributed: attributed,
                 alignment: .center,
                 lineCount: 1,
                 stringCasing: .unchanged)

        self.currentDate = date
    }
}
