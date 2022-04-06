//
//  Emot.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionCirclesView: BaseView {

    // Physics
    private lazy var animator = UIDynamicAnimator(referenceView: self)
    private let collisionBehavior = UICollisionBehavior()
    private let itemBehavior = UIDynamicItemBehavior()
    private let noiseField = UIFieldBehavior.noiseField(smoothness: 1, animationSpeed: 0.01)

    /// A collection of all the emotions this view should display along the number of times each emotion was selected.
    private(set) var emotionCounts: [Emotion : Int] = [:]

    /// All of the circle views corresponding to the current set of emotions.
    private var circleViews: [EmotionCircleView] = []

    override func initializeSubviews() {
        super.initializeSubviews()

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

        self.prepareNoiseField()
    }

    func configure(with emotions: [Emotion]) {
        // Update the emotions data
        self.emotionCounts.removeAll()
        emotions.forEach { emotion in
            let previousCount = self.emotionCounts[emotion] ?? 0
            self.emotionCounts[emotion] = previousCount + 1
        }

        self.setNeedsLayout()
    }

    func prepareNoiseField() {
        // Remove the existing circle views
        self.circleViews.removeAllFromSuperview(andRemoveAll: true)

        // Reset the physics behaviors
        self.collisionBehavior.removeAllItems()
        self.itemBehavior.removeAllItems()
        self.noiseField.removeAllItems()

        self.animator.behaviors.forEach { behavior in
            guard behavior is UIPushBehavior else { return }
            self.animator.removeBehavior(behavior)
        }


        // Create a circle view for each emotion and randomly distribute them within the boundaries.
        for (emotion, count) in self.emotionCounts {
            let emotionView = EmotionCircleView(emotion: emotion)

            let sizeMultiplier = sqrt(CGFloat(count))
            emotionView.squaredSize = 100 * sizeMultiplier
            emotionView.origin = CGPoint(x: CGFloat.random(in: 0...self.width - emotionView.width),
                                         y: CGFloat.random(in: 0...self.height - emotionView.height))

            self.addSubview(emotionView)

            // Give the view a little push to get it moving.
            let pushBehavior = UIPushBehavior(items: [emotionView], mode: .instantaneous)
            pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.1)
            self.animator.addBehavior(pushBehavior)

            self.collisionBehavior.addItem(emotionView)
            self.itemBehavior.addItem(emotionView)
            self.noiseField.addItem(emotionView)
        }
    }
}

private class EmotionCircleView: BaseView {

    let emotion: Emotion

    init(emotion: Emotion) {
        self.emotion = emotion

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.backgroundColor = self.emotion.color
        self.clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.halfWidth
    }

    // MARK: - UIDynamicItem

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}

// MARK: - UIDynamics Convenience Functions

private extension UICollisionBehavior {

    func removeAllItems() {
        self.items.forEach { item in
            self.removeItem(item)
        }
    }
}

private extension UIDynamicItemBehavior {

    func removeAllItems() {
        self.items.forEach { item in
            self.removeItem(item)
        }
    }
}

private extension UIFieldBehavior {

    func removeAllItems() {
        self.items.forEach { item in
            self.removeItem(item)
        }
    }
}
