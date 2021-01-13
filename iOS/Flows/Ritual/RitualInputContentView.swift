//
//  RitualInputContentView.swift
//  Benji
//
//  Created by Martin Young on 8/13/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RitualInputContentView: View {

    let timeLabel = RitualTimeLabel()
    let everyDayLabel = Label(font: .smallBold)

    let plusButton = Button()
    let minusButton = Button()
    let timeHump = TimeHumpView()
    let confirmButton = Button()

    var labelOffset: CGFloat = 20

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.timeLabel)
        self.timeLabel.textAlignment = .center
        
        self.addSubview(self.everyDayLabel)
        self.everyDayLabel.setText("EVERY DAY")
        self.everyDayLabel.textAlignment = .center
        self.everyDayLabel.stringCasing = .uppercase

        self.addSubview(self.plusButton)
        self.plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        self.plusButton.tintColor = Color.lightPurple.color
        self.plusButton.alpha = 0

        self.addSubview(self.minusButton)
        self.minusButton.setImage(UIImage(systemName: "minus"), for: .normal)
        self.minusButton.tintColor = Color.lightPurple.color
        self.minusButton.alpha = 0
        
        self.addSubview(self.confirmButton)
        self.addSubview(self.timeHump)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.confirmButton.setSize(with: self.width)
        self.confirmButton.bottom = self.height
        self.confirmButton.centerOnX()

        self.timeHump.size = CGSize(width: self.width * 0.9, height: 140)
        self.timeHump.bottom = self.confirmButton.top - 20
        self.timeHump.centerOnX()

        self.everyDayLabel.setSize(withWidth: 200)
        self.everyDayLabel.centerOnX()
        self.everyDayLabel.match(.bottom, to: .top, of: self.timeHump, offset: self.labelOffset)

        self.timeLabel.setSize(withWidth: 240)
        self.timeLabel.width = 240
        self.timeLabel.centerOnX()
        self.timeLabel.match(.bottom, to: .top, of: self.everyDayLabel, offset: -10)

        let padding: CGFloat = (self.width - self.timeLabel.width - 100) * 0.5
        self.minusButton.size = CGSize(width: 50, height: 50)
        self.minusButton.centerY = self.timeLabel.centerY
        self.minusButton.pin(.left, padding: padding)

        self.plusButton.size = CGSize(width: 50, height: 50)
        self.plusButton.centerY = self.timeLabel.centerY
        self.plusButton.pin(.right, padding: padding)
    }

    func set(date: Date) {
        self.timeLabel.set(date: date)
        self.setNeedsLayout()
    }

    func animateContent(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.minusButton.alpha = shouldShow ? 1 : 0
            self.plusButton.alpha = shouldShow ? 1 : 0
            self.labelOffset = shouldShow ? -100 : -20
            self.timeHump.alpha = shouldShow ? 1 : 0 
            self.layoutNow()
        }
    }
}
