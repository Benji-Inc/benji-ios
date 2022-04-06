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
    private var emotionViews: [EmotionCircleView] {
        return self.subviews.compactMap { view in
            return view as? EmotionCircleView
        }
    }

    /// The diameter an emotion view with an emotion count of 1.
    private let emotionViewDiameter: CGFloat = 100

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

        self.noiseField.strength = 10
        self.animator.addBehavior(self.noiseField)

        self.animator.delegate = self
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

    private func prepareNoiseField() {
        self.resetAnimatorAndViews()

        // Don't attempt to add emotion views if there's no space for them.
        guard self.size.width > 0, self.size.height > 0 else { return }

        // Create a circle view for each emotion and randomly distribute them within the boundaries.
        for (emotion, count) in self.emotionCounts {
            let emotionView = EmotionCircleView(emotion: emotion)

            let sizeMultiplier = sqrt(CGFloat(count))
            emotionView.squaredSize = clamp(self.emotionViewDiameter * sizeMultiplier,
                                            0,
                                            min(self.width, self.height))

            emotionView.origin = CGPoint(x: CGFloat.random(in: 0...self.width - emotionView.width),
                                         y: CGFloat.random(in: 0...self.height - emotionView.height))

            self.addSubview(emotionView)

            // Give the view a little push to get it moving.
            let pushBehavior = UIPushBehavior(items: [emotionView], mode: .instantaneous)
            pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.2)
            pushBehavior.action = { [unowned self, unowned pushBehavior] in
                // Clean up the push after it's done
                guard !pushBehavior.active else { return }
                self.animator.removeBehavior(pushBehavior)
            }
            self.animator.addBehavior(pushBehavior)

            self.collisionBehavior.addItem(emotionView)
            self.itemBehavior.addItem(emotionView)
            self.noiseField.addItem(emotionView)
        }
    }

    private func resetAnimatorAndViews() {
        // Remove the existing emotion views
        self.emotionViews.forEach { emotionView in
            emotionView.removeFromSuperview()
        }

        // Reset the physics behaviors
        self.collisionBehavior.removeAllItems()
        self.itemBehavior.removeAllItems()
        self.noiseField.removeAllItems()
    }
}

extension EmotionCirclesView: UIDynamicAnimatorDelegate {

    func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator) {
        logDebug("did resume "+animator.description)
    }


    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        logDebug("did pause "+animator.description)
    }
}

private class EmotionCircleView: BaseView {

    let emotion: Emotion

    private let label = ThemeLabel(font: .regular, textColor: .white)

    init(emotion: Emotion) {
        self.emotion = emotion

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.backgroundColor = self.emotion.color.withAlphaComponent(0.6)
        self.clipsToBounds = true

        self.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.halfWidth

        self.label.text = emotion.rawValue
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
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
