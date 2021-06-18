//
//  MessageBubbleVeiw.swift
//  Ours
//
//  Created by Benji Dodgson on 1/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageBubbleView: View, Indexable {

    var indexPath: IndexPath?
    private let circleView = View()
    var startingPoint: CGPoint = .zero

    private let selectionImpact = UIImpactFeedbackGenerator()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.circleView.alpha = 0
        self.insertSubview(self.circleView, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.circleView.height = self.height * 3
        self.circleView.width = self.width * 3
    }

    func startFillAnimation(at startingPoint: CGPoint,
                            for message: Messageable,
                            completion: @escaping (Messageable) -> Void) {

        self.selectionImpact.impactOccurred()

        let color: Color

        if !message.isFromCurrentUser, message.context == .passive {
            color = .purple
        } else {
            color = message.context.color
        }

        self.circleView.alpha = 0
        self.circleView.layer.cornerRadius = self.circleView.halfHeight
        self.circleView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        self.circleView.center = startingPoint
        self.circleView.set(backgroundColor: color)

        UIView.animate(withDuration: 0.5) {
            self.circleView.transform = .identity
            self.circleView.alpha = 1.0
            self.layer.borderColor = color.color.cgColor
            self.setNeedsLayout()
        } completion: { completed in
            completion(message)
        }
    }
}

