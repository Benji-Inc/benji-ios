//
//  ConversationReplyOverlayView.swift
//  ConversationReplyOverlayView
//
//  Created by Martin Young on 10/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationSendOverlayView: View {

    private let borderLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()

        self.borderLayer.strokeColor = UIColor(white: 1, alpha: 0.5).cgColor
        self.borderLayer.lineDashPattern = [10, 10]
        self.borderLayer.fillColor = nil
        self.borderLayer.lineWidth = 4
        self.borderLayer.frame = self.bounds
        self.borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 20).cgPath

        self.layer.addSublayer(self.borderLayer)
    }
}
