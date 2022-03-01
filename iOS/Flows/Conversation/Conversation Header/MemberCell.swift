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

    let avatarView = BorderedAvatarView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.avatarView.squaredSize = self.contentView.height
        self.avatarView.centerOnXAndY()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.avatarView)
    }

    func configure(with item: Member) {
        self.avatarView.set(avatar: item.displayable.value)

        Task {
            let userId = item.displayable.value.personId
            guard let user = await PeopleStore.shared.findUser(with: userId) else { return }

            self.subscribeToUpdates(for: user)
        }
                
        let typingUsers = item.conversationController.conversation.currentlyTypingUsers
        if typingUsers.contains(where: { typingUser in
            typingUser.personId == item.displayable.value.personId
        }) {
            self.avatarView.beginTyping()
        } else {
            self.avatarView.endTyping()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.avatarView.set(avatar: nil)
    }
    
    private func subscribeToUpdates(for user: User) {
//        UserStore.shared.$userUpdated.filter { updatedUser in
//            updatedUser?.objectId == user.userObjectId
//        }.mainSink { updatedUser in
//           // self.statusView.update(status: updatedUser?.focusStatus ?? .available)
//        }.store(in: &self.cancellables)
//        
//        //self.statusView.update(status: user.focusStatus ?? .available)
    }
}
