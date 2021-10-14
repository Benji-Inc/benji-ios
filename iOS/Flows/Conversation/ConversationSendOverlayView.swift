//
//  ConversationReplyOverlayView.swift
//  ConversationReplyOverlayView
//
//  Created by Martin Young on 10/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationSendOverlayView: View {

    private var borderLayer: CAShapeLayer?

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let borderLayer: CAShapeLayer

        if let borderLayerStrong = self.borderLayer {
            borderLayer = borderLayerStrong
        } else {
            borderLayer = CAShapeLayer()
            borderLayer.strokeColor = UIColor.white.cgColor
            borderLayer.lineDashPattern = [10, 10]
            borderLayer.fillColor = nil
            borderLayer.lineWidth = 4

            self.borderLayer = borderLayer
            self.layer.addSublayer(borderLayer)
        }

        borderLayer.frame = self.bounds
        borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 20).cgPath
    }
}
