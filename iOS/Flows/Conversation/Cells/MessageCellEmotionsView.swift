//
//  Emot.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageCellEmotionsView: BaseView {

    // Subviews
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))

    // Physics
    private lazy var animator = UIDynamicAnimator(referenceView: self)
    private let collisionBehavior = UICollisionBehavior()
    private let itemBehavior = UIDynamicItemBehavior()
    private let noiseField = UIFieldBehavior.noiseField(smoothness: 1, animationSpeed: 0.01)

    private(set) var emotions: [Emotion] = []

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.effectView)

        self.collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.collisionBehavior.collisionMode = .boundaries
        self.animator.addBehavior(self.collisionBehavior)

        self.itemBehavior.elasticity = 1
        self.itemBehavior.friction = 0
        self.itemBehavior.resistance = 0
        self.itemBehavior.angularResistance = 0
        self.animator.addBehavior(self.itemBehavior)

        self.noiseField.strength = 0.01
        self.animator.addBehavior(self.noiseField)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.addSubview(self.effectView)
    }

    func configure() {

    }


    func prepareNoiseField() {

        let numAcross = 4
        let numDown = 2

        for i in 0..<numAcross {
            for j in 0..<numDown {

                let horizontalSpacing: CGFloat = 428/CGFloat(numAcross)
                let verticalSpacing: CGFloat = 926/CGFloat(numDown)

                let circleView = CircleView(frame: CGRect(x: horizontalSpacing/4 + CGFloat(i)*horizontalSpacing,
                                                          y: verticalSpacing/3 + CGFloat(j)*verticalSpacing,
                                                          width: 100,
                                                          height: 100))

                circleView.addSubview(label)
                circleView.backgroundColor = UIColor(hue: CGFloat.random(in: 0...1),
                                                     saturation: 1,
                                                     brightness: 1,
                                                     alpha: 0.7)

                circleView.layer.cornerRadius = circleView.frame.width/2
                self.view.addSubview(circleView)

                let gravityField = UIFieldBehavior.radialGravityField(position: circleView.center)
                gravityField.strength = 0.2
                gravityField.addItem(circleView)
                gravityField.region = UIRegion(radius: 100).inverse()
                self.animator.addBehavior(gravityField)

                let pushBehavior = UIPushBehavior(items: [circleView], mode: .instantaneous)
                pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.2)
                self.animator.addBehavior(pushBehavior)

                self.collisionBehavior.addItem(circleView)
                self.itemBehavior.addItem(circleView)
                self.noiseField.addItem(circleView)
            }
        }
    }
}

extension ViewController: UICollisionBehaviorDelegate {

    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?,
                           at p: CGPoint) {

        guard let view = item as? UIView else { return }

        let vector = CGVector(dx: item.center.x - p.x, dy: item.center.y - p.y)
        let pushBehavior = UIPushBehavior(items: [view], mode: .instantaneous)
        pushBehavior.pushDirection = vector
        pushBehavior.magnitude = 0.2
        self.animator.addBehavior(pushBehavior)
    }
}

class CircleView: UIView {

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}

