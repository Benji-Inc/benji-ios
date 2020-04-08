//
//  ChannelCellContentView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelContentView: View {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private(set) var titleLabel = DisplayUnderlinedLabel()
    private let stackedAvatarView = StackedAvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.stackedAvatarView)
        self.addSubview(self.titleLabel)
        self.set(backgroundColor: .clear)
    }

    func configure(with type: ChannelType) {

        switch type {
        case .system(let channel):
            self.stackedAvatarView.set(items: channel.avatars)
        case .channel(let channel):
            channel.getMembersAsUsers()
                .observeValue(with: { (users) in
                    runMain {
                        let notMeUsers = users.filter { (user) -> Bool in
                            return user.objectId != User.current()?.objectId
                        }

                        self.stackedAvatarView.set(items: notMeUsers)
                        self.layoutNow()
                    }
                })

            if let context = channel.context {
                self.titleLabel.set(text: type.displayName, color: context.color)
            } else {
                self.titleLabel.set(text: type.displayName, color: .white)
            }

            self.layoutNow()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.stackedAvatarView.right = self.width - Theme.contentOffset
        self.stackedAvatarView.centerOnY()

        self.titleLabel.setSize(withWidth: self.width * 0.7)
        self.titleLabel.left = Theme.contentOffset + 4
        self.titleLabel.bottom = self.stackedAvatarView.bottom
    }

    func reset() {
        self.titleLabel.text = nil
        self.stackedAvatarView.set(items: [])
    }
}
