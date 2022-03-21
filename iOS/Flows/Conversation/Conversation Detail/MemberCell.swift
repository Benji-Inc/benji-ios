//
//  MemberCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Lottie

struct Member: Hashable {
    
    var personId: String
    var conversationController: ConversationController

    static func ==(lhs: Member, rhs: Member) -> Bool {
        return lhs.personId == rhs.personId
    }

    func hash(into hasher: inout Hasher) {
        self.personId.hash(into: &hasher)
    }
}

class MemberCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Member

    var currentItem: Member?

    let personView = BorderedPersonView()
    
    let nameLabel = ThemeLabel(font: .medium)
    
    let timeLabel = ThemeLabel(font: .small)
    
    let focusLabel = ThemeLabel(font: .small)
    let focusCircle = BaseView()
        
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.personView)
        
        self.personView.contextCueView.currentSize = .large
        self.personView.contextCueView.isVisible = false
        
        self.addSubview(self.nameLabel)
        
        self.addSubview(self.timeLabel)
    
        self.addSubview(self.focusLabel)
        self.focusLabel.setTextColor(.D1)
        
        self.addSubview(self.focusCircle)
        
        self.subscribeToUpdates()
    }

    /// A reference to a task for configuring the cell.
    private var configurationTask: Task<Void, Never>?

    func configure(with item: Member) {
        self.configurationTask?.cancel()

        self.configurationTask = Task {
            let personId = item.personId
            guard let person = await PeopleStore.shared.getPerson(withPersonId: personId) else { return }

            guard !Task.isCancelled else { return }

            self.personView.set(person: person)
            self.nameLabel.setText(person.givenName)
            
            if let user = person as? User {
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
            
            let typingUsers = item.conversationController.conversation.currentlyTypingUsers
            if typingUsers.contains(where: { typingUser in
                typingUser.personId == personId
            }) {
                self.personView.beginTyping()
            } else {
                self.personView.endTyping()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = self.contentView.height - Theme.ContentOffset.xtraLong.value.doubled
        self.personView.centerOnY()
        self.personView.pin(.left)
        
        self.focusCircle.squaredSize = 10
        self.focusCircle.makeRound()
        self.focusCircle.match(.left, to: .right, of: self.personView, offset: .long)
        self.focusCircle.match(.bottom, to: .bottom, of: self.personView)
        
        self.focusLabel.setSize(withWidth: self.width)
        self.focusLabel.match(.left, to: .right, of: self.focusCircle, offset: .short)
        self.focusLabel.centerY = self.focusCircle.centerY
        
        self.timeLabel.setSize(withWidth: self.width)
        self.timeLabel.match(.left, to: .right, of: self.focusLabel, offset: .short)
        self.timeLabel.centerY = self.focusLabel.centerY
        
        self.nameLabel.setSize(withWidth: self.width)
        self.nameLabel.match(.bottom, to: .top, of: self.focusCircle, offset: .negative(.standard))
        self.nameLabel.match(.left, to: .left, of: self.focusCircle)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.configurationTask?.cancel()
        self.personView.set(person: nil)
    }
    
    private func subscribeToUpdates() {
        // Make sure that the person's focus status up to date.
        PeopleStore.shared.$personUpdated.filter { [unowned self] updatedPerson in
            self.currentItem?.personId == updatedPerson?.personId
        }.mainSink { [unowned self] updatedPerson in
            self.personView.set(person: updatedPerson)
        }.store(in: &self.cancellables)
    }
}
