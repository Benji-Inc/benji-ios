//
//  ContactCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie
import Contacts

class ContactCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = CNContact

    private let avatarView = AvatarView()
    private let titleLabel = Label(font: .regularBold, textColor: .lightPurple)
    private let subTitleLabel = Label(font: .small)
    private let animationView = AnimationView.with(animation: .checkbox)

    var didTapButton: CompletionOptional = nil
    var currentItem: CNContact?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.animationView)
    }


    func configure(with item: CNContact) {

        self.avatarView.set(avatar: item)
        self.titleLabel.setText(item.fullName)
        let phone = item.findBestPhoneNumber().phone?.stringValue ?? ""
        self.subTitleLabel.setText(phone)
        self.layoutNow()
    }

    override func update(isSelected: Bool) {
        let progress: AnimationProgressTime = isSelected ? 1.0 : 0.0
        self.animationView.play(toProgress: progress)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.height - Theme.contentOffset)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.centerOnY()

        self.subTitleLabel.setSize(withWidth: self.contentView.width * 0.6)
        self.subTitleLabel.match(.bottom, to: .bottom, of: self.avatarView)
        self.subTitleLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset.half)

        self.titleLabel.setSize(withWidth: self.contentView.width * 0.6)
        self.titleLabel.match(.bottom, to: .top, of: self.subTitleLabel, offset: -4)
        self.titleLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset.half)

        self.animationView.squaredSize = 20
        self.animationView.pin(.right, padding: Theme.contentOffset)
        self.animationView.centerOnY()
    }
}
