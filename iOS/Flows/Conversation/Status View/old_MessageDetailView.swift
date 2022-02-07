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

class old_MessageDetailView: BaseView {

    static let height: CGFloat = 25

    let statusView = old_MessageStatusView()
    let emotionView = old_EmotionView()
    private var isAtTop: Bool = false

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
    
    func handleTopMessage(isAtTop: Bool) {
        guard self.isAtTop != isAtTop else { return }
        
        if isAtTop {
            self.statusView.handleConsumption()
        } else {
            self.statusView.resetConsumption()
        }
        
        self.isAtTop = isAtTop
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
