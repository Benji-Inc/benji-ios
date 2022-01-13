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
    
    let shadowLayer = CAShapeLayer()

    lazy var pulseLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.lineWidth = 1.5
        shape.lineCap = .round
        shape.fillColor = UIColor.clear.cgColor
        shape.cornerRadius = Theme.innerCornerRadius
        shape.borderColor = ThemeColor.D6.color.cgColor
        shape.borderWidth = 2
        return shape
    }()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.avatarView)
        
        self.layer.insertSublayer(self.pulseLayer, at: 2)
        #warning("update the status view designs")
        //self.contentView.addSubview(self.statusView)
        
        self.contentView.layer.insertSublayer(self.shadowLayer, below: self.avatarView.layer)
        
        self.shadowLayer.shadowColor = ThemeColor.D6.color.cgColor
        self.shadowLayer.shadowOpacity = 0.35
        self.shadowLayer.shadowOffset = .zero
        self.shadowLayer.shadowRadius = 10
    }

    func configure(with item: Member) {
        self.avatarView.set(avatar: item.displayable.value)
        
        Task {
            if let userId = item.displayable.value.userObjectId,
               let user = await UserStore.shared.findUser(with: userId) {
                self.subscribeToUpdates(for: user)
            }
        }
                
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
        
//        self.statusView.squaredSize = self.height * 0.45
//        self.statusView.match(.right, to: .right, of: self.avatarView, offset: .short)
//        self.statusView.match(.bottom, to: .bottom, of: self.avatarView, offset: .short)
        
        self.shadowLayer.shadowPath = UIBezierPath(rect: self.avatarView.frame).cgPath
    }

    private func beginTyping() {
        self.pulseLayer.removeAllAnimations()
        self.pulseLayer.strokeColor = ThemeColor.D6.color.cgColor
        
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
    
    private func subscribeToUpdates(for user: User) {
        UserStore.shared.$userUpdated.filter { updatedUser in
            updatedUser?.objectId == user.userObjectId
        }.mainSink { updatedUser in
           // self.statusView.update(status: updatedUser?.focusStatus ?? .available)
        }.store(in: &self.cancellables)
        
        //self.statusView.update(status: user.focusStatus ?? .available)
    }
}
