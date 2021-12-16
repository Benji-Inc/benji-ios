//
//  CircleTapView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AnimatingTapView: BaseView {

    private let circleView = BaseView()
    var startingPoint: CGPoint = .zero

    override func initializeSubviews() {
        super.initializeSubviews()

        self.circleView.alpha = 0
        self.insertSubview(self.circleView, at: 0)
        self.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.circleView.squaredSize = self.height * 3
    }

    func startFillAnimation(at startingPoint: CGPoint, completion: CompletionOptional = nil) {
        let color = Color.textColor.color.withAlphaComponent(0.15)
        self.circleView.alpha = 0
        self.circleView.layer.cornerRadius = self.circleView.halfHeight
        self.circleView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        self.circleView.center = startingPoint
        self.circleView.backgroundColor = color

        UIView.animate(withDuration: 0.25) {
            self.circleView.transform = .identity
            self.circleView.alpha = 1.0
            self.layer.borderColor = color.cgColor
            self.setNeedsLayout()
        } completion: { completed in
            UIView.animate(withDuration: 0.2) {
                self.circleView.alpha = 0.0
            } completion: { completed in
                completion?()
            }
        }
    }
}
