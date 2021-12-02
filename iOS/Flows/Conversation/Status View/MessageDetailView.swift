//
//  TimeSentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class MessageDetailView: View {

    private lazy var collectionView = ReactionsCollectionView()
    private lazy var manager = ReactionsManager(with: self.collectionView)

    let statusView = MessageStatusView()

    private var hasLoadedMessage: Message?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.collectionView)
        self.addSubview(self.statusView)
    }

    func configure(with message: Messageable) {
        self.manager.loadReactions(for: message)
        self.statusView.configure(for: message)
        self.layoutNow()
    }

    func updateReadStatus(shouldRead: Bool) {
        if shouldRead {
            self.statusView.handleConsumption()
        } else {
            self.statusView.resetConsumption()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewHeight()
        self.collectionView.pin(.left, offset: .standard)
        self.collectionView.width = self.halfWidth

        self.statusView.width = self.halfWidth
        self.statusView.pin(.right, offset: .standard)
        self.statusView.expandToSuperviewHeight()
    }
}
