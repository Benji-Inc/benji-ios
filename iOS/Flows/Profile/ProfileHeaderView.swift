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
    
    static let height: CGFloat = 100 
    
    let nameLabel = ThemeLabel(font: .medium)
    let memberLabel = ThemeLabel(font: .small)
    
    let localLabel = ThemeLabel(font: .small)
    let timeLabel = ThemeLabel(font: .small)
    
    let statusLabel = ThemeLabel(font: .small)
    let focusLabel = ThemeLabel(font: .small)
    let focusCircle = BaseView()
        
    let personView = BorderedPersonView()
    
    let menuButton = SymbolButton(symbol: .ellipsis)
    
    var didSelectUpdateProfilePicture: CompletionOptional = nil
    
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
        self.addSubview(self.personView)
        
        self.addSubview(self.menuButton)
        self.menuButton.set(tintColor: .whiteWithAlpha)
        self.menuButton.poinSize = 24
        self.menuButton.showsMenuAsPrimaryAction = true
    }
    
    @MainActor
    func configure(with person: PersonType) {
        self.personView.set(person: person)
        self.nameLabel.setText(person.givenName)

        if let user = person as? User {
            if let position = user.quePosition {
                self.memberLabel.setText("#\(position)")
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
        
        self.menuButton.menu = self.createMenu(for: person)
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = 100
        self.personView.pin(.left, offset: .xtraLong)
        self.personView.pin(.bottom)
        
        self.focusCircle.squaredSize = 10
        self.focusCircle.makeRound()
        self.focusCircle.match(.left, to: .right, of: self.personView, offset: .xtraLong)
        self.focusCircle.match(.bottom, to: .bottom, of: self.personView)
        
        self.focusLabel.setSize(withWidth: self.width)
        self.focusLabel.match(.left, to: .right, of: self.focusCircle, offset: .short)
        self.focusLabel.centerY = self.focusCircle.centerY

        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.match(.left, to: .right, of: self.focusLabel, offset: .short)
        self.statusLabel.centerY = self.focusCircle.centerY
        
        self.timeLabel.setSize(withWidth: self.width)
        self.timeLabel.match(.left, to: .left, of: self.nameLabel)
        self.timeLabel.match(.bottom, to: .top, of: self.focusCircle, offset: .negative(.standard))
        
        self.localLabel.setSize(withWidth: self.width)
        self.localLabel.match(.left, to: .right, of: self.timeLabel, offset: .short)
        self.localLabel.centerY = self.timeLabel.centerY
        
        self.nameLabel.setSize(withWidth: self.width)
        self.nameLabel.match(.bottom, to: .top, of: self.timeLabel, offset: .negative(.standard))
        self.nameLabel.match(.left, to: .right, of: self.personView, offset: .xtraLong)
        
        self.memberLabel.setSize(withWidth: self.width)
        self.memberLabel.match(.left, to: .right, of: self.nameLabel, offset: .short)
        self.memberLabel.bottom = self.nameLabel.bottom - 2
        
        self.menuButton.squaredSize = 44
        self.menuButton.pin(.right)
        self.menuButton.pin(.top, offset: .negative(.xtraLong))
    }
    
    private func createMenu(for person: PersonType) -> UIMenu? {
        guard person.isCurrentUser else { return nil }
        
        let remove = UIAction(title: "Update Picture",
                              image: ImageSymbol.camera.image,
                              attributes: []) { [unowned self] action in
            self.didSelectUpdateProfilePicture?()
        }

        return UIMenu.init(title: "Menu",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: [remove])
    }
}
