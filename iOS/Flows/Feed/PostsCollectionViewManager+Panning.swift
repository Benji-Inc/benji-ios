//
//  PostsCollectionViewManager+Panning.swift
//  Ours
//
//  Created by Benji Dodgson on 6/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension PostsCollectionManager: UIGestureRecognizerDelegate {

    func handle(pan: UIPanGestureRecognizer, for postVC: PostViewController) {

        let currentPoint = pan.location(in: nil)

        switch pan.state {
        case .began:
            self.transitionAnimator = self.createAnimator()
            self.panStartPoint = currentPoint
        case .changed:
            if self.interactionInProgress {
                let progress = self.progress(currentPoint: currentPoint)
                self.transitionAnimator?.fractionComplete = progress
            } else if currentPoint.y + self.panStartPoint.y > self.threshold {
                self.interactionInProgress = true
                self.startPoint = currentPoint
            }

        case .ended, .cancelled, .failed:
            self.interactionInProgress = false

            let isReversed = self.progress(currentPoint: currentPoint) < 0.5
            self.transitionAnimator?.isReversed = isReversed
            self.transitionAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)

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

    func createAnimator() -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 1.0,
                                              curve: .linear,
                                              animations: nil)

        self.transitionAnimator?.pausesOnCompletion = true
        self.transitionAnimator?.isInterruptible = true
        self.transitionAnimator?.isUserInteractionEnabled = true
        self.transitionAnimator?.pauseAnimation()
        return animator
    }

//    private func createAnimator() {
//        guard self.animator.isNil else { return }
//
//        self.animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear, animations: { [weak self] in
//            guard let `self` = self else { return }
//
//            let viewToAnimate = self.attachment.isNil ? self.imageView : self.videoView
//            let layer = viewToAnimate.layer
//            var transform = CATransform3DIdentity
//            transform.m34 = 1.0 / -500
//            transform = CATransform3DRotate(transform, 85.0 * .pi / 180.0, 1.0, 0.0, 0.0)
//
//            let move = CATransform3DMakeTranslation(0, -400, 0)
//            let new = CATransform3DConcat(transform, move)
//            let scale = CATransform3DScale(new, 0.5, 0.5, 0.5)
//
//            UIView.animateKeyframes(withDuration: 0.0, delay: 0.0, options: .allowUserInteraction) {
//
//                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
//                    layer.transform = scale
//                }
//
//                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
//                    self.swipeLabel.alpha = 0.0
//                    self.swipeLabel.transform = CGAffineTransform(translationX: 0.0, y: -200)
//                }
//
//                UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.5) {
//                    viewToAnimate.alpha = 0.0
//                }
//
//            } completion: { _ in
//                viewToAnimate.alpha = 0
//                self.swipeLabel.alpha = 0
//            }
//        })
//
//        self.animator?.addCompletion({ [weak self] (position) in
//            guard let `self` = self else { return }
//            // Animator completes initially on pause, so we also need to check progress
//            if position == .end {
//                self.createPost().mainSink { result in
//                    switch result {
//                    case .success(_):
//                        self.finishSaving()
//                    case .error(let error):
//                        print(error)
//                        self.reset()
//                    }
//                }.store(in: &self.cancellables)
//            }
//            self.animator = nil
//        })
//
//        self.animator?.scrubsLinearly = true
//        self.animator?.isInterruptible = true
//        self.animator?.pauseAnimation()
//        self.prepareInitialAnimation()
//    }

    //reset the animation
//    func prepareInitialAnimation() {
//
//        if self.attachment.isNil {
//            self.imageView.alpha = 1.0
//            self.imageView.transform = .identity
//        } else {
//            self.videoView.alpha = 1.0
//            self.videoView.transform = .identity
//        }
//
//        self.swipeLabel.alpha = 1.0
//        self.swipeLabel.transform = .identity
//        self.captionTextView.alpha = 1.0
//    }
}
