//
//  ChannelCell.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

class ChannelCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = DisplayableChannel

    var currentItem: DisplayableChannel?
    private let stackedAvatarView = StackedAvatarView()
    private let label = Label(font: .small, textColor: .background4)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.stackedAvatarView)
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        self.stackedAvatarView.itemHeight = 80
    }

    func configure(with item: DisplayableChannel) {
        switch item.channelType {
        case .channel(let channel):
            self.display(channel: channel)
        default:
            break
        }
    }

    private func display(channel: TCHChannel) {
        channel.getUsers(excludeMe: true)
            .mainSink(receiveValue: { (users) in
                if let friendlyName = channel.friendlyName {
                    self.label.setText(friendlyName)
                } else if users.count == 0 {
                    self.label.setText("You")
                } else if users.count == 1, let user = users.first(where: { user in
                    return user.objectId != User.current()?.objectId
                }) {
                    self.displayDM(for: channel, with: user)
                } else {
                    self.displayGroupChat(for: channel, with: users)
                }
                self.stackedAvatarView.set(items: users)
                self.stackedAvatarView.layoutNow()
                self.layoutNow()

            }).store(in: &self.cancellables)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: 110)
        return layoutAttributes
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.stackedAvatarView.setSize()
        self.stackedAvatarView.pin(.top)
        self.stackedAvatarView.centerOnX()

        self.label.setSize(withWidth: self.contentView.width * 0.9)
        self.label.match(.top, to: .bottom, of: self.stackedAvatarView, offset: 5)
        self.label.centerOnX()
    }

    private func displayDM(for channel: TCHChannel, with user: User) {
        user.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.label.setText(user.fullName)
                self.layoutNow()
            }).store(in: &self.cancellables)
    }

    func displayGroupChat(for channel: TCHChannel, with users: [User]) {
        var text = ""
        for (index, user) in users.enumerated() {
            if index < users.count - 1 {
                text.append(String("\(user.givenName), "))
            } else if index == users.count - 1 && users.count > 1 {
                text.append(String("\(user.givenName)"))
            } else {
                text.append(user.givenName)
            }
        }
    }
}
