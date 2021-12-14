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

    static let height: CGFloat = 20

    let statusView = MessageStatusView()
    let emotionView = EmotionView()

    private var hasLoadedMessage: Message?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.emotionView)
        self.emotionView.button.isEnabled = false 
        self.addSubview(self.statusView)
    }

    func configure(with message: Messageable) {
        self.emotionView.configure(for: message)
        self.statusView.configure(for: message)
        self.layoutNow()
    }

    func update(with message: Messageable) {
        self.emotionView.configure(for: message)
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

        self.emotionView.expandToSuperviewHeight()
        self.emotionView.pin(.left, offset: .standard)

        self.statusView.width = self.halfWidth
        self.statusView.pin(.right, offset: .standard)
        self.statusView.expandToSuperviewHeight()
    }
}
