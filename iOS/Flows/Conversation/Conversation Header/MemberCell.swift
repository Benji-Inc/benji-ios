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
        return lhs.displayable.value.userObjectId == rhs.displayable.value.userObjectId
    }

    func hash(into hasher: inout Hasher) {
        self.displayable.value.userObjectId.hash(into: &hasher)
    }
}

class MemberCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Member

    var currentItem: Member?

    let avatarView = AvatarView()
    
    lazy var pulseLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.lineWidth = 1.5
        shape.lineCap = .round
        shape.fillColor = UIColor.clear.cgColor
        shape.cornerRadius = Theme.cornerRadius
        return shape
    }()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.avatarView)
        
        self.layer.addSublayer(self.pulseLayer)
    }

    func configure(with item: Member) {
        self.avatarView.set(avatar: item.displayable.value)

        let typingUsers = item.conversationController.conversation.currentlyTypingUsers
        if typingUsers.contains(where: { typingUser in
            typingUser.userObjectId == item.displayable.value.userObjectId
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
        
        self.pulseLayer.frame = self.avatarView.bounds
        self.pulseLayer.path = UIBezierPath(roundedRect: self.avatarView.bounds, cornerRadius: Theme.innerCornerRadius).cgPath
        self.pulseLayer.position = self.avatarView.center
    }

    private func beginTyping() {
        self.pulseLayer.removeAllAnimations()
        self.pulseLayer.strokeColor = ThemeColor.white.color.cgColor
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.toValue = 1.2
        scale.fromValue = 1.0
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.toValue = 1.0
        fade.fromValue = 0.35
        
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 1
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.autoreverses = true
        group.repeatCount = .infinity
        
        self.pulseLayer.add(group, forKey: "pulsing")
    }

    private func endTyping() {
        self.pulseLayer.strokeColor = ThemeColor.clear.color.cgColor
        self.pulseLayer.removeAllAnimations()
    }
}
