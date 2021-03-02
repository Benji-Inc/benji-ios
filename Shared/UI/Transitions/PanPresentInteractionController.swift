//
//  PanPresentInteractionController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PanPresentInteractionController: UIPercentDrivenInteractiveTransition {

    var onStartPresent: (() -> Void)?

    var interactionInProgress = false // If we're currently in a dismiss interaction

    // Distance, in points, a pan must move vertically before a presentation call
    private let presentThreshold: CGFloat = 10
    // Distance that a pan must move to fully present the view controller
    private let presentDistance: CGFloat = 250

    private var panStartPoint = CGPoint() // Where the pan gesture began
    private var presentStartPoint = CGPoint() // Where the pan gesture was when a dismissal was started

    // Sets up the passed in view with a gesture recognizer to allow it to handle presentation interactions.
    func initialize(interactionView: UIView) {

        let panGesture = UIPanGestureRecognizer { [unowned self] (pan) in
            self.handle(pan: pan)
        }
        // Make sure this is true so we don't register a tap after the pan is lifted
        panGesture.cancelsTouchesInView = true
        panGesture.delegate = self
        interactionView.addGestureRecognizer(panGesture)
    }

    func handle(pan: UIPanGestureRecognizer) {

        let currentPoint = pan.location(in: nil)

        switch pan.state {
        case .began:
            self.panStartPoint = currentPoint

        case .changed:
            if self.interactionInProgress {
                let progress = self.progress(currentPoint: currentPoint)
                self.update(progress)
            } else if self.panStartPoint.y - currentPoint.y  > self.presentThreshold {
                // Only start dismissing the view controller if the pan drags far enough
                self.interactionInProgress = true
                self.presentStartPoint = currentPoint

                self.onStartPresent?()
            }

        case .ended, .cancelled, .failed:
            self.interactionInProgress = false

            if self.percentComplete > 0.3 || pan.velocity(in: nil).y < -400 {
                self.finish()
            } else {
                self.cancel()
            }

        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func progress(currentPoint: CGPoint) -> CGFloat {
        let progress = (self.presentStartPoint.y - currentPoint.y) / self.presentDistance
        return clamp(progress, 0.0, 1.0)
    }
}

extension PanPresentInteractionController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }

        // Only allow vertical scrolling for presentation. This allows collection views
        // to scroll horizontally.
        let velocity = panRecognizer.velocity(in: nil)
        return abs(velocity.y) > abs(velocity.x) && velocity.y < 0
    }
}
