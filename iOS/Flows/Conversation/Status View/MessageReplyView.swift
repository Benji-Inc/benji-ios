//
//  MessageReplyView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageReplyView: MessageStatusContainer {

    let countLabel = ThemeLabel(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.countLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countLabel.setSize(withWidth: self.maxWidth)

        if self.countLabel.text.isNil {
            self.width = 0
        } else {
            self.width = self.minWidth
        }
        
        self.countLabel.centerOnXAndY()
    }

    func setReplies(for message: Message) {
        if message.replyCount > 0 {
            self.countLabel.setText("\(message.replyCount)")
        } else {
            self.countLabel.text = nil
        }
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.layoutNow()
        }
    }

    func reset() {
        self.countLabel.text = nil
    }
}
