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
    }

    private let borderLayer = CAShapeLayer()
    private let sendTypeLabel = Label(font: .small)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.sendTypeLabel)
        self.sendTypeLabel.text = "Drop"
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.sendTypeLabel.sizeToFit()
        self.sendTypeLabel.pin(.top, padding: self.sendTypeLabel.height)
        self.sendTypeLabel.centerOnX()

        self.borderLayer.strokeColor = UIColor(white: 1, alpha: 0.5).cgColor
        self.borderLayer.lineDashPattern = [10, 10]
        self.borderLayer.fillColor = nil
        self.borderLayer.lineWidth = 4
        self.borderLayer.frame = self.bounds
        self.borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 20).cgPath

        self.layer.addSublayer(self.borderLayer)
    }

    func setState(_ state: State?) {
        switch state {
        case .reply:
            self.sendTypeLabel.isHidden = true
        case .newMessage:
            self.sendTypeLabel.isHidden = false
        case .none:
            self.sendTypeLabel.isHidden = true
        }
    }
}
