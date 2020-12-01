//
//  ChannelCell.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

class ChannelCell: UICollectionViewCell, ManageableCell {
    typealias ItemType = DisplayableChannel

    var onLongPress: (() -> Void)?
    private let avatarView = AvatarView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeViews() {
        self.contentView.addSubview(self.avatarView)
    }

    func configure(with item: DisplayableChannel?) {
        guard let displayable = item else { return }

        switch displayable.channelType {
        case .system(_):
            break
        case .channel(let channel):
            self.configure(channel: channel)
        case .pending(_):
            break
        }
    }

    private func configure(channel: TCHChannel) {

        channel.getMembersAsUsers()
            .observeValue(with: { (users) in
                runMain {
                    let notMeUsers = users.filter { (user) -> Bool in
                        return user.objectId != User.current()?.objectId
                    }

                    if let first = notMeUsers.first {
                        self.avatarView.set(avatar: first)
                        self.layoutNow()
                    }
                }
            })
    }

    func collectionViewManagerWillDisplay() {}
    func collectionViewManagerDidEndDisplaying() {}

    override func prepareForReuse() {
        super.prepareForReuse()

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.width)
        self.avatarView.centerOnXAndY()
    }
}
