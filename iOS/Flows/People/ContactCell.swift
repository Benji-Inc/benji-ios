//
//  ContactCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import Contacts
import PhoneNumberKit

class ContactCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Contact

    private let avatarView = AvatarView()
    private let titleLabel = Label(font: .regularBold, textColor: .textColor)
    private let subTitleLabel = Label(font: .small, textColor: .textColor)
    private let animationView = AnimationView.with(animation: .checkbox)
    private let content = BaseView()

    var didTapButton: CompletionOptional = nil
    var currentItem: Contact?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.content)
        self.content.set(backgroundColor: .darkGray)

        self.content.addSubview(self.avatarView)
        self.content.addSubview(self.titleLabel)
        self.content.addSubview(self.subTitleLabel)
        self.content.addSubview(self.animationView)
    }

    func configure(with item: Contact) {
        self.avatarView.set(avatar: item)
        self.titleLabel.setText(item.fullName)
        self.subTitleLabel.setText(item.phoneNumber)
        self.layoutNow()
    }

    override func update(isSelected: Bool) {
        let progress: AnimationProgressTime = isSelected ? 1.0 : 0.0
        self.animationView.play(toProgress: progress)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
        self.content.roundCorners()

        self.avatarView.setSize(for: self.contentView.height - Theme.contentOffset)
        self.avatarView.pin(.left, offset: .standard)
        self.avatarView.centerOnY()

        self.subTitleLabel.setSize(withWidth: self.contentView.width * 0.6)
        self.subTitleLabel.top = self.avatarView.centerY + 4
        self.subTitleLabel.match(.left, to: .right, of: self.avatarView, offset: .standard)

        self.titleLabel.setSize(withWidth: self.contentView.width * 0.6)
        self.titleLabel.bottom = self.avatarView.centerY
        self.titleLabel.match(.left, to: .right, of: self.avatarView, offset: .standard)

        self.animationView.squaredSize = 20
        self.animationView.pin(.right, offset: .xtraLong)
        self.animationView.centerOnY()
    }
}
