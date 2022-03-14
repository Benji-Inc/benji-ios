//
//  ProfileHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class ProfileHeaderView: BaseView {
    
    let nameLabel = ThemeLabel(font: .medium)
    let memberLabel = ThemeLabel(font: .small)
    
    let localLabel = ThemeLabel(font: .small)
    let timeLabel = ThemeLabel(font: .small)
    
    let statusLabel = ThemeLabel(font: .small)
    let focusLabel = ThemeLabel(font: .small)
    let focusCircle = BaseView()
    
    let bottomLabel = ThemeLabel(font: .regular)
    
    let personView = BorderedPersonView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.personView.contextCueView.currentSize = .large
        self.personView.contextCueView.isVisible = false
        
        self.addSubview(self.nameLabel)
        
        self.addSubview(self.memberLabel)
        self.memberLabel.alpha = 0.25
        
        self.addSubview(self.localLabel)
        self.localLabel.alpha = 0.25
        self.localLabel.setText("Local Time")
        
        self.addSubview(self.timeLabel)
        
        self.addSubview(self.statusLabel)
        self.statusLabel.setText("Focus Status")
        self.statusLabel.alpha = 0.25
        
        self.addSubview(self.focusLabel)
        self.focusLabel.setTextColor(.D1)
        
        self.addSubview(self.focusCircle)
        
        self.addSubview(self.bottomLabel)
        self.bottomLabel.textAlignment = .center
        self.bottomLabel.setText("What I'm up to...")
        
        self.addSubview(self.personView)
    }
    
    @MainActor
    func configure(with person: PersonType) {
        self.personView.set(person: person)
        self.nameLabel.setText(person.givenName)

        if let user = person as? User {
            if let position = user.quePosition {
                self.memberLabel.setText("Member #\(position)")
            }

            if user.isCurrentUser {
                let nowTime = Date.hourMinuteTimeOfDay.string(from: Date())
                self.timeLabel.setText(nowTime)
            } else {
                self.timeLabel.setText(user.getLocalTime())
            }
        }

        if let status = person.focusStatus {
            self.focusLabel.setText(status.displayName.firstCapitalized)
            self.focusLabel.setTextColor(status.color)
            self.focusCircle.set(backgroundColor: status.color)
        } else {
            self.focusLabel.setTextColor(.yellow)
            self.focusLabel.setText("Unavailable")
            self.focusCircle.set(backgroundColor: FocusStatus.focused.color)
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.bottomLabel.setSize(withWidth: self.width)
        self.bottomLabel.pin(.bottom, offset: .standard)
        self.bottomLabel.pin(.left, offset: .xtraLong)
        
        self.personView.squaredSize = 100
        self.personView.match(.left, to: .left, of: self.bottomLabel)
        self.personView.match(.bottom, to: .top, of: self.bottomLabel, offset: .negative(.xtraLong))
        
        self.nameLabel.setSize(withWidth: self.width)
        self.nameLabel.centerY = self.personView.centerY - Theme.ContentOffset.xtraLong.value
        self.nameLabel.match(.left, to: .right, of: self.personView, offset: .xtraLong)
        
        self.memberLabel.setSize(withWidth: self.width)
        self.memberLabel.match(.left, to: .right, of: self.nameLabel, offset: .short)
        self.memberLabel.bottom = self.nameLabel.bottom
        
        self.timeLabel.setSize(withWidth: self.width)
        self.timeLabel.match(.left, to: .left, of: self.nameLabel)
        self.timeLabel.centerY = self.personView.centerY + Theme.ContentOffset.xtraLong.value
        
        self.localLabel.setSize(withWidth: self.width)
        self.localLabel.match(.left, to: .right, of: self.timeLabel, offset: .short)
        self.localLabel.centerY = self.timeLabel.centerY
        
        self.focusCircle.squaredSize = 10
        self.focusCircle.makeRound()
        self.focusCircle.match(.left, to: .left, of: self.timeLabel)
        self.focusCircle.match(.top, to: .bottom, of: self.timeLabel, offset: .standard)
        
        self.focusLabel.setSize(withWidth: self.width)
        self.focusLabel.match(.left, to: .right, of: self.focusCircle, offset: .short)
        self.focusLabel.centerY = self.focusCircle.centerY

        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.match(.left, to: .right, of: self.focusLabel, offset: .short)
        self.statusLabel.centerY = self.focusCircle.centerY
    }
}
