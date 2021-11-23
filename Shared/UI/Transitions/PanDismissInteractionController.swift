//
//  PanDismissInteractionController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PanDismissInteractionController: UIPercentDrivenInteractiveTransition {

    unowned let viewController: UIViewController

    var interactionInProgress = false // If we're currently in a dismiss interaction

    let dismissThreshold: CGFloat = 10 // Distance, in points, a pan must move vertically before a dismissal
    let dismissDistance: CGFloat = 250 // Distance that a pan must move to fully dismiss the view controller

    var panStartPoint = CGPoint() // Where the pan gesture began
    var dismissStartPoint = CGPoint() // Where the pan gesture was when a dismissal was started

    init(viewController: UIViewController) {

        self.viewController = viewController

        super.init()
    }

    func initialize(collectionView: UICollectionView) {
        collectionView.panGestureRecognizer.addTarget(self, action: #selector(self.handle(pan:)))
    }

    @objc func handle(pan: UIPanGestureRecognizer) {

        let currentPoint = pan.location(in: nil)

        switch pan.state {
        case .began:
            if let cv = pan.view as? UICollectionView, cv.contentOffset.y < 0 {
                self.panStartPoint = currentPoint
            }
        case .changed:
            if self.interactionInProgress {
                if let cv = pan.view as? UICollectionView {
                    let progress = self.progress(currentPoint: currentPoint, collectionView: cv)
                    self.update(progress)
                }
            } else if currentPoint.y - self.panStartPoint.y > self.dismissThreshold {
                // Only start dismissing the view controller if the pan drags far enough
                self.interactionInProgress = true
                self.dismissStartPoint = currentPoint
                // Calling dismiss here will ensure interruptibleAnimator gets called
                self.viewController.dismiss(animated: true, completion: nil)
            }

        case .ended, .cancelled, .failed:
            self.interactionInProgress = false

            if self.percentComplete > 0.3 || pan.velocity(in: nil).y > 400  {
                if let cv = pan.view as? UICollectionView, cv.contentOffset.y < 0 {
                    self.finish()
                } else {
                    self.cancel()
                }
            } else {
                self.cancel()
            }

        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func progress(currentPoint: CGPoint, collectionView: UICollectionView) -> CGFloat {
        logDebug("yOFFset: \(collectionView.contentOffset.y)")
        guard collectionView.contentOffset.y < 0 else { return 0.0 }

        let progress = (currentPoint.y - self.dismissStartPoint.y) / self.dismissDistance
        return clamp(progress, 0.0, 1.0)
    }
}

extension PanDismissInteractionController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }

        // Only allow vertical scrolling for presentation. This allows collection views
        // to scroll horizontally.
        let velocity = panRecognizer.velocity(in: nil)
        return abs(velocity.y) > abs(velocity.x) && velocity.y > 0
    }
}
