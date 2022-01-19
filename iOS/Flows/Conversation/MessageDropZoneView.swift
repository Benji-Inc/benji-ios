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
    private let sendTypeLabel = ThemeLabel(font: .regular)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.borderLayer.lineDashPattern = [4, 6]
        self.borderLayer.lineWidth = 1
        self.layer.addSublayer(self.borderLayer)
        self.addSubview(self.sendTypeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.sendTypeLabel.setSize(withWidth: self.width)
        self.sendTypeLabel.centerOnXAndY()
        
        self.borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 5).cgPath
    }

    func setState(_ state: State?, messageColor: ThemeColor?) {
        switch state {
        case .reply:
            self.sendTypeLabel.setText("Drop reply here")
            self.sendTypeLabel.isHidden = false
        case .newMessage:
            self.sendTypeLabel.setText("Drop message here")
            self.sendTypeLabel.isHidden = false
        case .newConversation:
            self.sendTypeLabel.setText("Drop message here")
            self.sendTypeLabel.isHidden = false
            self.set(backgroundColor: .clear)
        case .none:
            self.sendTypeLabel.isHidden = true
        }

        self.setColors(for: messageColor)

        self.layoutNow()
    }

    func setColors(for messageColor: ThemeColor?) {
        guard let color = messageColor else {
            self.borderLayer.strokeColor = ThemeColor.B1.color.cgColor
            self.sendTypeLabel.setTextColor(.T3)
            self.borderLayer.fillColor = ThemeColor.clear.color.cgColor
            return
        }

        if color != .B1 {
            self.borderLayer.strokeColor = color.color.cgColor
            self.sendTypeLabel.setTextColor(color)
        } else {
            self.borderLayer.strokeColor = ThemeColor.B1.color.cgColor
            self.sendTypeLabel.setTextColor(.T3)
        }

        self.borderLayer.fillColor = ThemeColor.clear.color.cgColor
    }
}
