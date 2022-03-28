//
//  MessageReadCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageReadCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = Member
    
    var currentItem: Member?
    
    let personView = BorderedPersonView()
    let nameLabel = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.personView)
        
        self.personView.contextCueView.currentSize = .large
        self.personView.contextCueView.isVisible = false
        
        self.addSubview(self.nameLabel)
        self.nameLabel.textAlignment = .center
        
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
            
            self.setNeedsLayout()
            
            guard let typingUsers = item.conversationController?.conversation.currentlyTypingUsers else { return }
            
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
        
        self.nameLabel.setSize(withWidth: self.contentView.width)
        self.nameLabel.centerOnX()
        self.nameLabel.pin(.bottom)
        
        self.personView.squaredSize = self.contentView.height * 0.6
        self.personView.centerOnX()
        self.personView.match(.bottom, to: .top, of: self.nameLabel, offset: .negative(.short))
    }
    
    private func subscribeToUpdates() {
        // Make sure that the person's focus status up to date.
        PeopleStore.shared.$personUpdated.filter { [unowned self] updatedPerson in
            self.currentItem?.personId == updatedPerson?.personId
        }.mainSink { [unowned self] updatedPerson in
            self.personView.set(person: updatedPerson)
        }.store(in: &self.cancellables)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.configurationTask?.cancel()
        self.personView.set(person: nil)
    }
}

