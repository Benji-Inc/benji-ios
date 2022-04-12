//
//  EmotionCircleCollectionView.swift
//  Jibber
//
//  Created by Martin Young on 4/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class EmotionCircleCollectionView: BaseView {

    private let circleDiameter: CGFloat

    // MARK: - State Variable
    /// The emotions that should be displayed along with their corresponding counts.
    private(set) var emotionCounts: [Emotion : Int] = [:]
    /// All of the emotion views added as subviews.
    private var emotionsViews: [Emotion : EmotionCircleView] = [:]

    // MARK: - Physics
    private lazy var animator = UIDynamicAnimator(referenceView: self)
    private let collisionBehavior = UICollisionBehavior()
    private let itemBehavior = UIDynamicItemBehavior()
    private let noiseField = UIFieldBehavior.noiseField(smoothness: 0.2, animationSpeed: 1)

    // MARK: - Life cycle

    init(cellDiameter: CGFloat) {
        self.circleDiameter = cellDiameter

        super.init()
    }

    required init?(coder: NSCoder) {
        self.circleDiameter = 80
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

    /// This views bounds when it was last laid out.
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
            self.removeAllEmotions()
            self.setEmotionsCounts(savedEmotionCounts)
        }
    }

    /// Displays emotion circles configured by the passed in emotion counts.
    func setEmotionsCounts(_ emotionsCounts: [Emotion : Int]) {
        self.emotionCounts = emotionsCounts

        for (emotion, count) in emotionsCounts {
            // If we already have a view for this emotion, animate any size changes needed.
            if let emotionView = self.emotionsViews[emotion] {
                self.resizeEmotionView(emotionView, withCount: count)
            } else {
                // If we don't already have a view created for this emotion, create one now.
                self.createAndAddEmotionsView(with: emotion, count: count)
            }
        }

        // Clean up unneeded emotion views.
        self.removeUnusedEmotionViews()
    }

    // MARK: - Emotion View Management

    /// Creates a new emotion view to display the given emotion and sized for the passed in count.
    /// The view is added as a subview and added to the animator.
    private func createAndAddEmotionsView(with emotion: Emotion, count: Int) {
        guard self.width > 0, self.height > 0 else { return }

        let emotionView = EmotionCircleView(emotion: emotion)
        let finalSize = self.getSize(forCount: count)
        // Start the view in a random position
        emotionView.frame.origin = self.getRandomPosition(forCount: count)

        // Start the view off small and invisible. It will be animated to its final size and alpha.
        emotionView.alpha = 0
        emotionView.size = CGSize(width: 1, height: 1) // The initial size must be non-zero for the animator.

        // Start managing this view
        self.emotionsViews[emotion] = emotionView
        self.addSubview(emotionView)

        // Give the view a little push to get it moving.
        let pushBehavior = UIPushBehavior(items: [emotionView], mode: .instantaneous)
        pushBehavior.setAngle(CGFloat.random(in: 0...CGFloat.pi*2), magnitude: 0.3)
        pushBehavior.action = { [unowned self, unowned pushBehavior] in
            // Clean up the push after it's done
            guard !pushBehavior.active else { return }
            self.animator.removeBehavior(pushBehavior)
        }

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            emotionView.alpha = 1
            emotionView.size = finalSize
            emotionView.layoutNow()
        } completion: { completed in
            guard completed else { return }
            // Once we're done animating, the view's transform can be managed by the animator.
            self.animator.addBehavior(pushBehavior)
            self.collisionBehavior.addItem(emotionView)
            self.itemBehavior.addItem(emotionView)
            self.noiseField.addItem(emotionView)
        }
    }

    /// Resizes the emotion view to a size appropriate for the passed in count.
    private func resizeEmotionView(_ emotionView: EmotionCircleView, withCount count: Int) {
        // Animate the size
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            emotionView.size = self.getSize(forCount: count)
            // Call layout now so subviews are animated as well.
            emotionView.layoutNow()
            self.animator.updateItem(usingCurrentState: emotionView)
        }
    }

    /// Removes as a subview the view corresponding to the given emotion. The view is also removed from the animator.
    private func removeEmotionView(for emotion: Emotion) {
        guard let emotionView = self.emotionsViews[emotion] else { return }

        // Stop managing this view.
        self.emotionsViews.removeValue(forKey: emotion)

        // Animate out the view and remove it from the physics behaviors.
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            emotionView.size = CGSize(width: 1, height: 1)
            emotionView.alpha = 0
            emotionView.layoutNow()
        } completion: { _ in
            emotionView.removeFromSuperview()
            self.collisionBehavior.removeItem(emotionView)
            self.itemBehavior.removeItem(emotionView)
            self.noiseField.removeItem(emotionView)
        }
    }

    /// Removes all emotion views that no longer have a related emotion count.
    private func removeUnusedEmotionViews() {
        for emotion in self.emotionsViews.keys {
            guard self.emotionCounts[emotion].isNil else { continue }
            self.removeEmotionView(for: emotion)
        }
    }

    /// Removes all the emotion counts and their corresponding views.
    private func removeAllEmotions() {
        self.emotionCounts.removeAll()
        for emotion in self.emotionsViews.keys {
            self.removeEmotionView(for: emotion)
        }
    }

    // MARK: - Helper Functions

    /// Gets the appropriate size for an emotion circle view taking this view's size and the emotion count into account.
    private func getSize(forCount count: Int) -> CGSize {
        let scale = sqrt(CGFloat(count))
        let clampedDiameter = clamp(self.circleDiameter * scale,
                                    0,
                                    min(self.width, self.height))

        return CGSize(width: clampedDiameter, height: clampedDiameter)
    }

    /// Gets an appropriate random starting position for an emotion view with the given count.
    private func getRandomPosition(forCount count: Int) -> CGPoint {
        let size = self.getSize(forCount: count)

        return CGPoint(x: CGFloat.random(in: 0...self.width - size.width),
                       y: CGFloat.random(in: 0...self.height - size.height))
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
