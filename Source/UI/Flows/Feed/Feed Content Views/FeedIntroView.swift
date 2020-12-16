//
//  FeedIntroView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class FeedIntroView: View {

    private let timeLabel = newLabel(font: .displayThin, textColor: .lightPurple)
    private let label = newLabel(font: .regular)
    private let descritpionLabel = newLabel(font: .small, textColor: .background3)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.timeLabel)
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.addSubview(self.descritpionLabel)
        self.descritpionLabel.textAlignment = .center
    }

    func set(count: Int) {
        if count > 0 {
            let time = count * 20
            let text = LocalizedString(id: "", arguments: [], default: "minutes of distractions avoided today.")
            self.timeLabel.setText("\(time)")
            self.label.setText(text)
        } else {
            self.timeLabel.setText("😌")
            self.label.setText("You had a distraction free day.")
        }

        self.descritpionLabel.setText("Each notification is a 20 minute distraction to your brain.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.timeLabel.setSize(withWidth: self.width)
        self.timeLabel.centerOnX()
        self.timeLabel.bottom = self.halfHeight - 5

        self.label.setSize(withWidth: self.width * 0.9)
        self.label.centerOnX()
        self.label.top = self.halfHeight + 5

        self.descritpionLabel.setSize(withWidth: self.width)
        self.descritpionLabel.centerOnX()
        self.descritpionLabel.bottom = self.bottom
    }
}
