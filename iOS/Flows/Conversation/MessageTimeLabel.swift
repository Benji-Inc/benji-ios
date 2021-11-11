//
//  ConversationTimeLabel.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageTimeLabel: Label {

    init() {
        super.init(font: .small)

        self.textAlignment = .center
        self.numberOfLines = 1
        self.setFont(.small)
        self.setTextColor(.gray)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(date: Date?) {
        guard let date = date else {
            self.text = nil
            return
        }

        self.text = Date.hourMinuteTimeOfDay.string(from: date)
    }
}
