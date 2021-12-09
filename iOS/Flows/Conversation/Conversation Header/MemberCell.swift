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

struct Member: Hashable, Equatable {
    var displayable: AnyHashableDisplayable
    var conversationController: ConversationController

    static func ==(lhs: Member, rhs: Member) -> Bool {
        return lhs.displayable.value.userObjectID == rhs.displayable.value.userObjectID
    }

    func hash(into hasher: inout Hasher) {
        self.displayable.value.userObjectID.hash(into: &hasher)
    }
}

class MemberCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Member

    var currentItem: Member?

    let avatarView = AvatarView()
    private var animationView = AnimationView.with(animation: .typing)
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.animationView)

        self.animationView.loopMode = .loop
    }

    func configure(with item: Member) {
        self.avatarView.set(avatar: item.displayable.value)

        let typingUsers = item.conversationController.conversation.currentlyTypingUsers
        if typingUsers.contains(where: { typingUser in
            typingUser.userObjectID == item.displayable.value.userObjectID
        }) {
            self.beginTyping()
        } else {
            self.endTyping()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.height)
        self.avatarView.centerOnXAndY()

        self.animationView.width = 12
        self.animationView.height = 6
        self.animationView.centerOnX()
        self.animationView.centerY = self.height
        self.animationView.layer.cornerRadius = 3
        self.animationView.layer.masksToBounds = true
    }

    private func beginTyping() {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.animationView.transform = .identity
            self.animationView.alpha = 1.0
        } completion: { _ in
            self.animationView.play()
        }
    }

    private func endTyping() {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.animationView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.animationView.alpha = 0.0
        } completion: { _ in
            self.animationView.stop()
        }
    }
}
