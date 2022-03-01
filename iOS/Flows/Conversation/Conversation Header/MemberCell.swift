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
    
    var displayable: AnyHashableDisplayable
    var conversationController: ConversationController

    static func ==(lhs: Member, rhs: Member) -> Bool {
        return lhs.displayable.value.personId == rhs.displayable.value.personId
    }

    func hash(into hasher: inout Hasher) {
        self.displayable.value.personId.hash(into: &hasher)
    }
}

class MemberCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Member

    var currentItem: Member?

    let personView = BorderedAvatarView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.personView.squaredSize = self.contentView.height
        self.personView.centerOnXAndY()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.personView)
    }

    func configure(with item: Member) {
        self.personView.set(person: item.displayable.value)

        Task {
            let personId = item.displayable.value.personId
            guard let person = await PeopleStore.shared.getPerson(withPersonId: personId) else { return }

            self.subscribeToUpdates(for: person)
        }
                
        let typingUsers = item.conversationController.conversation.currentlyTypingUsers
        if typingUsers.contains(where: { typingUser in
            typingUser.personId == item.displayable.value.personId
        }) {
            self.personView.beginTyping()
        } else {
            self.personView.endTyping()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.personView.set(person: nil)
    }
    
    private func subscribeToUpdates(for person: PersonType) {
        #warning("restore this")
//        UserStore.shared.$userUpdated.filter { updatedUser in
//            updatedUser?.objectId == user.userObjectId
//        }.mainSink { updatedUser in
//           // self.statusView.update(status: updatedUser?.focusStatus ?? .available)
//        }.store(in: &self.cancellables)
//        
//        //self.statusView.update(status: user.focusStatus ?? .available)
    }
}
