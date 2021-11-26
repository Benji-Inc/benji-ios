//
//  ConversationReplyOverlayView.swift
//  ConversationReplyOverlayView
//
//  Created by Martin Young on 10/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A view used by the conversation VC to designate where to drag and drop new messages.
class MessageDropZoneView: View {

    enum State {
        case reply
        case newMessage
        case newConversation
    }

    private let borderLayer = CAShapeLayer()
    private let sendTypeLabel = Label(font: .regular)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.borderLayer.strokeColor = Color.lightGray.color.cgColor
        self.borderLayer.lineDashPattern = [5, 10]
        self.borderLayer.fillColor = Color.white.color.cgColor
        self.borderLayer.lineWidth = 2

        self.layer.addSublayer(self.borderLayer)

        self.addSubview(self.sendTypeLabel)
        self.sendTypeLabel.setTextColor(.lightGray)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.sendTypeLabel.setSize(withWidth: self.width)
        self.sendTypeLabel.centerOnXAndY()

        self.borderLayer.frame = self.bounds
        self.borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: Theme.cornerRadius).cgPath
    }

    func setState(_ state: State?) {
        switch state {
        case .reply:
            self.sendTypeLabel.setText("Drop new reply here")
            self.sendTypeLabel.isHidden = false
        case .newMessage:
            self.sendTypeLabel.setText("Drop new message here")
            self.sendTypeLabel.isHidden = false
        case .newConversation:
            self.sendTypeLabel.setText("Start a new conversation here")
            self.sendTypeLabel.isHidden = false
        case .none:
            self.sendTypeLabel.isHidden = true
        }

        self.layoutNow()
    }
}
