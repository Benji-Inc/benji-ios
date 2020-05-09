//
//  InviteableContentView.swift
//  Benji
//
//  Created by Benji Dodgson on 2/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import PhoneNumberKit

class InviteableContentView: View {

    private let avatarView = AvatarView()
    private let nameLabel = RegularBoldLabel()
    private let phoneNumberLabel = SmallLabel()
    private let statusLabel = SmallBoldLabel()
    private(set) var animationView = AnimationView(name: "checkbox")

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.avatarView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.phoneNumberLabel)
        self.addSubview(self.statusLabel)
        self.addSubview(self.animationView)
    }

    func configure(with inviteable: Inviteable) {

        switch inviteable {
        case .contact(_, let status):
            self.set(phoneNumber: inviteable.phoneNumber, avatar: inviteable)

            if status == .accepted || status == .invited {
                self.statusLabel.isVisible = true
                self.statusLabel.set(text: status.rawValue.uppercased(), color: .white, alignment: .right)
                self.animationView.isVisible = false 
            } else {
                self.animationView.isVisible = true
                self.statusLabel.isVisible = false
            }

        case .connection(let connection):
            connection.nonMeUser?.fetchIfNeededInBackground { (object, error) in
                guard let nonMeUser = object as? User else { return }
                self.set(phoneNumber: String(optional: nonMeUser.phoneNumber), avatar: nonMeUser)
                self.layoutNow()
            }

            if let status = connection.status {
                self.statusLabel.isVisible = true
                self.statusLabel.set(text: status.rawValue.uppercased(), color: .white, alignment: .right)
            }

            self.animationView.isVisible = false
        }
    }

    private func set(phoneNumber: String, avatar: Avatar) {

        self.nameLabel.set(text: avatar.fullName, stringCasing: .capitalized)
        let formattedPhone = PhoneKit.formatter.formatPartial(phoneNumber)
        self.phoneNumberLabel.set(text: formattedPhone, color: .background4)
        self.avatarView.set(avatar: avatar)

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: 60)
        self.avatarView.left = Theme.contentOffset
        self.avatarView.centerOnY()

        let width = self.width - self.avatarView.right - (Theme.contentOffset * 2)
        self.nameLabel.size = CGSize(width: width, height: 30)
        self.nameLabel.bottom = self.avatarView.centerY
        self.nameLabel.left = self.avatarView.right + Theme.contentOffset

        self.phoneNumberLabel.size = CGSize(width: width, height: 30)
        self.phoneNumberLabel.top = self.avatarView.centerY
        self.phoneNumberLabel.left = self.avatarView.right + Theme.contentOffset

        self.animationView.size = CGSize(width: 20, height: 20)
        self.animationView.centerOnY()
        self.animationView.right = self.right - Theme.contentOffset

        self.statusLabel.setSize(withWidth: self.halfWidth)
        self.statusLabel.right = self.animationView.right
        self.statusLabel.centerOnY()
    }

    func animateToChecked() {
        self.animationView.play(toFrame: 30)
    }

    func animateToUnchecked() {
        self.animationView.play(fromFrame: 30, toFrame: 0, loopMode: nil, completion: nil)
    }

    func reset() {
        self.nameLabel.text = nil
        self.phoneNumberLabel.text = nil
        self.statusLabel.text = nil
    }
}
