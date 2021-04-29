//
//  PostCreationViewController+Panning.swift
//  Ours
//
//  Created by Benji Dodgson on 4/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension PostCreationViewController: UIGestureRecognizerDelegate {

    func handle(pan: UIPanGestureRecognizer) {
        guard self.tabState == .review else { return }

        let currentPoint = pan.location(in: nil)

        switch pan.state {
        case .began:
            self.createAnimator()
            self.panStartPoint = currentPoint
        case .changed:
            if self.interactionInProgress {
                let progress = self.progress(currentPoint: currentPoint)
                self.animator?.fractionComplete = progress
            } else if currentPoint.y + self.panStartPoint.y > self.threshold {
                self.interactionInProgress = true
                self.startPoint = currentPoint
            }

        case .ended, .cancelled, .failed:
            self.interactionInProgress = false

            print(self.progress(currentPoint: currentPoint))
            self.animator?.isReversed = self.progress(currentPoint: currentPoint) < 1.0
            self.animator?.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)

        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func progress(currentPoint: CGPoint) -> CGFloat {
        let progress = (self.startPoint.y - currentPoint.y) / self.distance
        return clamp(progress, 0.0, 1.0)
    }
}
