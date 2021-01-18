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

    private let chatButton = Button()

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.avatarView)
        self.view.addSubview(self.localTimeLabel)
        self.view.addSubview(self.handleLabel)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.chatButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        
    }
}
