//
//  ChannelDetailBar.swift
//  Benji
//
//  Created by Benji Dodgson on 7/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import TMROLocalization

protocol ChannelDetailBarDelegate: class {
    func channelDetailBarDidTapMenu(_ view: ChannelDetailBar)
}

class ChannelDetailBar: View {

    private let titleButton = Button()
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)
    let channelType: ChannelType
    private let content = ChannelContentView()

    unowned let delegate: ChannelDetailBarDelegate

    init(with channelType: ChannelType, delegate: ChannelDetailBarDelegate) {
        self.delegate = delegate
        self.channelType = channelType
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.content)
        self.content.addSubview(self.titleButton)

        self.titleButton.didSelect = { [unowned self] in
            self.delegate.channelDetailBarDidTapMenu(self)
        }

        self.content.configure(with: self.channelType)

        self.subscribeToUpdates()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
        self.titleButton.frame = self.content.titleLabel.frame
    }

    private func subscribeToUpdates() {

        ChannelManager.shared.channelSyncUpdate.producer.on { [weak self] (update) in
            guard let `self` = self else { return }

            guard let channelsUpdate = update,
                channelsUpdate.channel == ChannelManager.shared.activeChannel.value else { return }

            switch channelsUpdate.status {
            case .all:
                self.content.configure(with: .channel(channelsUpdate.channel))
            default:
                break
            }
        }.start()
    }
}
