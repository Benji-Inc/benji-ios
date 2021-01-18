//
//  UserProfileViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserProfileViewController: ViewController {

    private let avatarView = AvatarView()
    private let localTimeLabel = Label(font: .smallBold)
    private let handleLabel = Label(font: .regularBold)
    private let nameLabel = Label(font: .mediumBold)
    private let vibrancyView = VibrancyView()

    private let chatButton = Button()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.avatarView)
        self.view.addSubview(self.localTimeLabel)
        self.view.addSubview(self.handleLabel)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.chatButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.vibrancyView.expandToSuperviewSize()

        self.avatarView.setSize(for: 120)
        self.avatarView.pin(.top, padding: Theme.contentOffset)
        self.avatarView.pin(.left, padding: Theme.contentOffset)

        let maxWidth = self.view.width - self.avatarView.right - Theme.contentOffset
        self.nameLabel.setSize(withWidth: maxWidth)
        self.nameLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
        self.nameLabel.match(.top, to: .top, of: self.avatarView)

        self.handleLabel.setSize(withWidth: maxWidth)
        self.handleLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
        self.handleLabel.match(.top, to: .bottom, of: self.nameLabel, offset: Theme.contentOffset)

//        self.localTimeLabel.setSize(withWidth: maxWidth)
//        self.localTimeLabel.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset)
//        self.localTimeLabel.match(.top, to: .bottom, of: self.nameLabel, offset: Theme.contentOffset)
    }

    func configure(with user: User) {
        self.avatarView.set(avatar: user)
        self.nameLabel.setText(user.fullName)
        self.handleLabel.setText(user.handle)
        self.view.layoutNow()
    }
}
