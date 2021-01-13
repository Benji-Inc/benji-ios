//
//  RoutineTimeOfDayLabel.swift
//  Benji
//
//  Created by Benji Dodgson on 12/1/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RitualTimeOfDayLabel: Label {

    override func initializeLabel() {
        super.initializeLabel()

        self.stringCasing = .uppercase
        self.setTextColor(.lightPurple)
        self.textAlignment = .left
    }

    func set(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        let string = formatter.string(from: date)
        self.setText(string)
    }
}
