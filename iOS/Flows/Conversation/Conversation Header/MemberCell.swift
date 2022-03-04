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

    let personView = BorderedPersoniew()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.personView.squaredSize = self.contentView.height
        self.personView.centerOnXAndY()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.personView)

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
