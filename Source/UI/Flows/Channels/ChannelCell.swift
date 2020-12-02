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

    private let channelContentView = ChannelContentView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.channelContentView)
    }

    func configure(with item: DisplayableChannel?) {
        guard let displayable = item else { return }

        self.channelContentView.configure(with: displayable.channelType)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.channelContentView.size = CGSize(width: self.contentView.width * 0.95,
                                              height: self.contentView.height)
        self.channelContentView.centerOnXAndY()
    }
}
