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
    
    let bottomLabel = ThemeLabel(font: .regular)
    
    let personView = BorderedPersoniew()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.nameLabel)
        self.nameLabel.textAlignment = .center
        self.addSubview(self.memberLabel)
        self.memberLabel.alpha = 0.5
        self.memberLabel.textAlignment = .center
        self.addSubview(self.localLabel)
        self.localLabel.alpha = 0.5
        self.localLabel.textAlignment = .right
        self.localLabel.setText("Local Time")
        self.addSubview(self.timeLabel)
        self.timeLabel.textAlignment = .right
        self.addSubview(self.statusLabel)
        self.statusLabel.setText("Focus Status")
        self.statusLabel.alpha = 0.5
        self.statusLabel.textAlignment = .left
        self.addSubview(self.focusLabel)
        self.focusLabel.setTextColor(.D1)
        self.focusLabel.textAlignment = .left
        self.addSubview(self.bottomLabel)
        self.bottomLabel.textAlignment = .center
        self.bottomLabel.setText("What I'm up to...")
        self.addSubview(self.personView)
    }
    
    @MainActor
    func configure(with user: User) {
        
        self.personView.set(person: user)
        self.nameLabel.setText(user.givenName)
        if let position = user.quePosition {
            self.memberLabel.setText("Member #\(position)")
        }
        
        if user.isCurrentUser {
            let nowTime = Date.hourMinuteTimeOfDay.string(from: Date())
            self.timeLabel.setText(nowTime)
        } else {
            self.timeLabel.setText(user.getLocalTime())
        }
        
        if let status = user.focusStatus {
            self.focusLabel.setText(status.rawValue.firstCapitalized)
        } else {
            self.focusLabel.setText("Unavailable")
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = 100
        self.personView.centerOnXAndY()
        
        self.memberLabel.setSize(withWidth: self.width)
        self.memberLabel.match(.bottom, to: .top, of: self.personView, offset: .negative(.xtraLong))
        self.memberLabel.centerOnX()
        
        self.nameLabel.setSize(withWidth: self.width)
        self.nameLabel.match(.bottom, to: .top, of: self.memberLabel, offset: .negative(.standard))
        self.nameLabel.centerOnX()
        
        self.localLabel.setSize(withWidth: self.width)
        self.localLabel.match(.right, to: .left, of: self.personView, offset: .negative(.xtraLong))
        self.localLabel.bottom = self.personView.centerY - 2
        
        self.timeLabel.setSize(withWidth: self.width)
        self.timeLabel.match(.right, to: .right, of: self.localLabel)
        self.timeLabel.top = self.personView.centerY + 2
        
        self.bottomLabel.setSize(withWidth: self.width)
        self.bottomLabel.match(.top, to: .bottom, of: self.personView, offset: .xtraLong)
        self.bottomLabel.centerOnX()
        
        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.match(.left, to: .right, of: self.personView, offset: .xtraLong)
        self.statusLabel.bottom = self.personView.centerY - 2
        
        self.focusLabel.setSize(withWidth: self.width)
        self.focusLabel.match(.left, to: .left, of: self.statusLabel)
        self.focusLabel.top = self.personView.centerY + 2
    }
}
