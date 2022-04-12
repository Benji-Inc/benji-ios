//
//  EmotionCircleCollectionView.swift
//  Jibber
//
//  Created by Martin Young on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionCircleCollectionView: BaseView {

    struct Item: Hashable {
        let emotion: Emotion
        let count: Int
        // TODO: Only hash on the emotion type
    }

    // Physics
    private lazy var animator = UIDynamicAnimator(referenceView: self)
    private let collisionBehavior = UICollisionBehavior()
    private let itemBehavior = UIDynamicItemBehavior()
    private let noiseField = UIFieldBehavior.noiseField(smoothness: 0.2, animationSpeed: 1)

    private let cellDiameter: CGFloat

    init(cellDiameter: CGFloat) {
        self.cellDiameter = cellDiameter

        super.init()
    }

    required init?(coder: NSCoder) {
        self.cellDiameter = 100
        super.init(coder: coder)
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.collisionBehavior.translatesReferenceBoundsIntoBoundary = false
        self.collisionBehavior.collisionMode = .boundaries
        self.collisionBehavior.collisionDelegate = self
        self.animator.addBehavior(self.collisionBehavior)

        self.itemBehavior.elasticity = 1
        self.itemBehavior.friction = 0
        self.itemBehavior.resistance = 0
        self.itemBehavior.angularResistance = 0
        self.animator.addBehavior(self.itemBehavior)

        self.noiseField.strength = 0.1
        self.animator.addBehavior(self.noiseField)
    }

    private var previousBounds: CGRect?

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the collision boundaries up to date with the collection view.
        self.collisionBehavior.removeAllBoundaries()
        self.collisionBehavior.addBoundary(withIdentifier: NSString(string: "boundary"),
                                           for: UIBezierPath(rect: self.bounds))

        // If the bounds change we may need to reposition our subviews so
        // they stay within the collision boundaries.
        if self.previousBounds != self.bounds {
            self.previousBounds = self.bounds

            let savedEmotionCounts = self.emotionCounts

            self.emotionCounts.removeAll()
            for emotion in self.emotionsViews.keys {
                guard let emotionView = self.emotionsViews[emotion] else { continue }
                self.removeEmotionView(emotionView)
                self.emotionsViews.removeValue(forKey: emotion)
            }

            self.setEmotions(savedEmotionCounts)
        }
    }

    var emotionCounts: [Emotion : Int] = [:]
    var emotionsViews: [Emotion : EmotionCircleView] = [:]

    func setEmotions(_ emotionsCounts: [Emotion : Int]) {
        let previousEmotionCounts = self.emotionCounts

        self.emotionCounts = emotionsCounts

        for (previousEmotion, count) in emotionsCounts {
            // If we already have a view for this emotion, animate any size changes needed
            if let emotionView = self.emotionsViews[previousEmotion] {
                // Animate the size
            } else {
                // If we don't already have a view created for this emotion, create one now.
                self.createEmotionsView(with: Item(emotion: previousEmotion, count: 1))
            }
        }

        // Find any emotion views whose types are not in the new set of items and clean them up.
        for (previousEmotion, count) in previousEmotionCounts {
            guard self.emotionCounts[previousEmotion].isNil,
                  let emotionView = self.emotionsViews[previousEmotion] else { return }

            self.removeEmotionView(emotionView)
        }
    }

    // MARK: - Animator Functions

    private func createEmotionsView(with emotionItem: Item) {
        guard self.width > 0, self.height > 0 else { return }

        let emotionView = EmotionCircleView()
        emotionView.configure(with: emotionItem.emotion)
        let clampedDiameter = clamp(self.cellDiameter,
                                    0,
                                    min(self.width, self.height))
        emotionView.size = CGSize(width: clampedDiameter, height: clampedDiameter)
        emotionView.frame.origin
        = CGPoint(x: CGFloat.random(in: 0...self.width - clampedDiameter),
                  y: CGFloat.random(in: 0...self.height - clampedDiameter))

        self.emotionsViews[emotionItem.emotion] = emotionView
        self.addSubview(emotionView)

        // Give the view a little push to get it moving.
        let pushBehavior = UIPushBehavior(items: [emotionView], mode: .instantaneous)
        pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.3)
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

    private func removeEmotionView(_ emotionView: EmotionCircleView) {
        emotionView.removeFromSuperview()
        self.collisionBehavior.removeItem(emotionView)
        self.itemBehavior.removeItem(emotionView)
        self.noiseField.removeItem(emotionView)
    }
}

extension EmotionCircleCollectionView: UICollisionBehaviorDelegate {

    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?,
                           at p: CGPoint) {

        // Lightly bounce away from the boundary.
        let vector = CGVector(dx: item.center.x - p.x, dy: item.center.y - p.y)
        let pushBehavior = UIPushBehavior(items: [item], mode: .instantaneous)
        pushBehavior.pushDirection = vector
        pushBehavior.magnitude = 0.05
        pushBehavior.action = { [unowned self, unowned pushBehavior] in
            // Clean up the push after it's done
            guard !pushBehavior.active else { return }
            self.animator.removeBehavior(pushBehavior)
        }

        self.animator.addBehavior(pushBehavior)
    }
}
