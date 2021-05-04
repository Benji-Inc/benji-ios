//
//  NewChannelCell.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie

class ConnectionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Connection

    private let avatarView = AvatarView()
    private let handleLabel = Label(font: .regularBold, textColor: .lightPurple)
    private let nameLabel = Label(font: .small)
    private let animationView = AnimationView(name: "checkbox")

    var didTapButton: CompletionOptional = nil
    var currentItem: Connection?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.handleLabel)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.animationView)
    }

    func configure(with item: Connection) {
        guard let nonMeUser = item.nonMeUser else { return }

        nonMeUser.retrieveDataIfNeeded()
            .mainSink { user in
                self.avatarView.set(avatar: nonMeUser)
                self.handleLabel.setText(nonMeUser.handle)
                self.nameLabel.setText(nonMeUser.fullName)
                self.layoutNow()
            }.store(in: &self.cancellables)
    }

    override func update(isSelected: Bool) {
        let progress: AnimationProgressTime = isSelected ? 1.0 : 0.0
        self.animationView.play(toProgress: progress)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.height - Theme.contentOffset.doubled)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.centerOnY()

        self.nameLabel.setSize(withWidth: self.contentView.width * 0.6)
        self.nameLabel.match(.bottom, to: .bottom, of: self.avatarView)
        self.nameLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)

        self.handleLabel.setSize(withWidth: self.contentView.width * 0.6)
        self.handleLabel.match(.bottom, to: .top, of: self.nameLabel, offset: -4)
        self.handleLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)

        self.animationView.squaredSize = 20
        self.animationView.pin(.right, padding: Theme.contentOffset)
        self.animationView.centerOnY()
    }
}
