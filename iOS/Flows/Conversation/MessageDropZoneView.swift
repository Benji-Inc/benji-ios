//
//  ConversationReplyOverlayView.swift
//  ConversationReplyOverlayView
//
//  Created by Martin Young on 10/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A view used by the conversation VC to designate where to drag and drop new messages.
class MessageDropZoneView: BaseView {

    enum State {
        case reply
        case newMessage
        case newConversation
    }

    private let borderLayer = CAShapeLayer()
    private let sendTypeLabel = Label(font: .regular)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.borderLayer.lineDashPattern = [3, 4]
        self.borderLayer.lineWidth = 1
        self.layer.addSublayer(self.borderLayer)
        self.addSubview(self.sendTypeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.sendTypeLabel.setSize(withWidth: self.width)
        self.sendTypeLabel.centerOnXAndY()

        self.borderLayer.frame = self.bounds
        self.borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 5).cgPath
    }

    func setState(_ state: State?, messageColor: Color?) {
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

        self.setColors(for: messageColor)

        self.layoutNow()
    }

    func setColors(for messageColor: Color?) {
        guard let color = messageColor else {
            self.borderLayer.strokeColor = Color.white.color.cgColor
            self.sendTypeLabel.setTextColor(.white)
            self.borderLayer.fillColor = Color.clear.color.cgColor
            return
        }

        if color != .white {
            self.borderLayer.strokeColor = color.color.cgColor
            self.sendTypeLabel.setTextColor(color)
        } else {
            self.borderLayer.strokeColor = Color.white.color.cgColor
            self.sendTypeLabel.setTextColor(.white)
        }

        self.borderLayer.fillColor = Color.clear.color.cgColor
    }
}
