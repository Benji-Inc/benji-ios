//
//  UserProfileViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class AvatarProfileViewController: ViewController {

    private let avatarView = AvatarView()
    private let handleLabel = Label(font: .small, textColor: .purple)
    private let nameLabel = Label(font: .mediumBold)
    private let ritualLabel = Label(font: .small, textColor: .white)
    private let vibrancyView = VibrancyView()

    private let chatButton = Button()
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
        self.view.addSubview(self.handleLabel)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.chatButton)
        self.view.addSubview(self.ritualLabel)

        self.avatarView.set(avatar: self.avatar)
        self.nameLabel.setText(self.avatar.fullName)
        self.handleLabel.setText(self.avatar.handle)

        self.getRitual()

        self.preferredContentSize = CGSize(width: 300, height: 300)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.vibrancyView.expandToSuperviewSize()

        self.avatarView.setSize(for: 120)
        self.avatarView.pin(.top, padding: Theme.contentOffset)
        self.avatarView.centerOnX()

        let maxWidth = self.view.width - (Theme.contentOffset * 2)

        self.nameLabel.setSize(withWidth: maxWidth)
        self.nameLabel.centerOnX()
        self.nameLabel.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset)

        self.handleLabel.setSize(withWidth: maxWidth)
        self.handleLabel.centerOnX()
        self.handleLabel.match(.top, to: .bottom, of: self.nameLabel, offset: 4)

        self.ritualLabel.setSize(withWidth: maxWidth)
        self.ritualLabel.centerOnX()
        self.ritualLabel.pin(.bottom, padding: Theme.contentOffset)
    }

    private func getRitual() {
        guard let user = self.avatar as? User else { return }

        if let ritualId = user.ritual?.objectId {
            Ritual.localThenNetworkQuery(for: ritualId)
                .mainSink(receiveValue: { (ritual) in
                    if let date = ritual.date {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let string = formatter.string(from: date)
                        self.ritualLabel.setText("Ritual begins everyday @ \(string)")
                    } else {
                        self.ritualLabel.setText("NO RITUAL SET")
                    }
                    self.view.layoutNow()
                }).store(in: &self.cancellables)
        } else {
            self.ritualLabel.setText("NO RITUAL SET")
        }
    }
}
