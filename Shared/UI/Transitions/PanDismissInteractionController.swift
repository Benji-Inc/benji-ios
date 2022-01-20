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

    let dismissThreshold: CGFloat = 20 // Distance, in points, a pan must move vertically before a dismissal
    let dismissDistance: CGFloat = 250 // Distance that a pan must move to fully dismiss the view controller

    var panStartPoint: CGPoint? // Where the pan gesture began

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
            if self.isReadyForDismissal(pan) {
                self.panStartPoint = currentPoint
            }
        case .changed:

            if self.interactionInProgress {
                let progress = self.isReadyForDismissal(pan) ? self.progress(currentPoint: currentPoint) : 0.0
                if progress > 0.01 {
                    self.viewController.resignFirstResponder()
                }
                self.update(progress)
            } else if self.panStartPoint.isNil, self.isReadyForDismissal(pan) {
                self.panStartPoint = currentPoint
            } else if let startY = self.panStartPoint?.y,
                      currentPoint.y > startY,
                      currentPoint.y - startY > self.dismissThreshold {
                
                logDebug("CurrentY: \(currentPoint.y)")
                logDebug("StartY: \(startY)")
                
                // Only start dismissing the view controller if the pan drags far enough
                self.interactionInProgress = true
                // Calling dismiss here will ensure interruptibleAnimator gets called
                self.viewController.dismiss(animated: true, completion: nil)
            }

        case .ended, .cancelled, .failed:
            self.interactionInProgress = false
            
            self.panStartPoint = nil

            if self.percentComplete > 0.3 || pan.velocity(in: nil).y > 400  {
                if self.isReadyForDismissal(pan) {
                    self.finish()
                } else {
                    if !self.viewController.isFirstResponder {
                        delay(0.1) {
                            self.viewController.becomeFirstResponder()
                        }
                    }
                    self.cancel()
                }
            } else {
                if !self.viewController.isFirstResponder {
                    delay(0.1) {
                        self.viewController.becomeFirstResponder()
                    }
                }
                self.cancel()
            }

        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func progress(currentPoint: CGPoint) -> CGFloat {
        guard let startY = self.panStartPoint?.y else { return 0.0 }
        let progress = (currentPoint.y - startY) / self.dismissDistance
        return clamp(progress, 0.0, 1.0)
    }

    private func isReadyForDismissal(_ pan: UIPanGestureRecognizer) -> Bool {
        guard let cv = pan.view as? UICollectionView else { return false }
        return cv.contentOffset.y < self.dismissThreshold
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
