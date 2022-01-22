//
//  UserProfileViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class AvatarProfileViewController: ViewController {

    private let avatarView = AvatarView()
    private let nameLabel = ThemeLabel(font: .mediumBold)
    private let vibrancyView = VibrancyView()

    private let chatButton = ThemeButton()
    private let avatar: Avatar

    init(with avatar: Avatar) {
        self.avatar = avatar
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .clear)
        self.view.addSubview(self.vibrancyView)
        self.view.addSubview(self.avatarView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.chatButton)

        if let objectId = self.avatar.userObjectId {
            Task {
                let user = await UserStore.shared.findUser(with: objectId)
                self.nameLabel.setText(user?.fullName)
                self.view.layoutNow()
            }.add(to: self.taskPool)
        }
        self.avatarView.set(avatar: self.avatar)

        self.preferredContentSize = CGSize(width: 300, height: 300)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.vibrancyView.expandToSuperviewSize()

        self.avatarView.setSize(for: 120)
        self.avatarView.pinToSafeAreaTop()
        self.avatarView.centerOnX()

        let maxWidth = Theme.getPaddedWidth(with: self.view.width)

        self.nameLabel.setSize(withWidth: maxWidth)
        self.nameLabel.centerOnX()
        self.nameLabel.match(.top, to: .bottom, of: self.avatarView, offset: .standard)
    }
}
