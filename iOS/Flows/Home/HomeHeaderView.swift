//
//  RoomHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/31/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class HomeHeaderView: BaseView {
        
    let button = ThemeButton()
    let focusLabel = ThemeLabel(font: .regularBold)
    let focusCircle = BaseView()
    
    let personView = BorderedPersonView()
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.focusLabel)
        self.addSubview(self.focusCircle)
        
        self.addSubview(self.personView)
        self.personView.contextCueView.currentSize = .small
        
        self.addSubview(self.button)
        
        PeopleStore.shared.$personUpdated
            .filter({ type in
                guard let t = type else { return false }
                return t.isCurrentUser
            })
            .mainSink { [unowned self] person in
                guard let person = person else { return }
                self.update(person: person)
        }.store(in: &self.cancellables)
        
        self.update(person: User.current()!)
    }
    
    private func update(person: PersonType) {
        
        if let status = person.focusStatus {
            self.focusLabel.setText(status.displayName)
            self.focusLabel.setTextColor(status.color)
            self.focusCircle.set(backgroundColor: status.color)
        } else {
            self.focusLabel.setText("Unavailable")
            self.focusLabel.setTextColor(FocusStatus.focused.color)
            self.focusCircle.set(backgroundColor: FocusStatus.focused.color)
        }
        
        self.personView.set(person: person)
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = 30
        self.personView.pin(.left, offset: .xtraLong)
        self.personView.centerOnY()
        
        self.focusLabel.setSize(withWidth: self.width)
        self.focusLabel.centerOnY()
        self.focusLabel.left = self.halfWidth - self.focusLabel.halfWidth + 4
        
        self.focusCircle.squaredSize = 10
        self.focusCircle.makeRound()
        self.focusCircle.match(.right, to: .left, of: self.focusLabel, offset: .negative(.standard))
        self.focusCircle.centerOnY()
        
        self.button.expandToSuperviewHeight()
        self.button.width = self.focusLabel.right
        self.button.pin(.left)
    }
}
