//
//  TransitionRouter+Home.swift
//  Ours
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

#if !APPCLIP
extension TransitionRouter {

    func homeTranstion(fromColor: Color,
                       transitionContext: UIViewControllerContextTransitioning) {

        guard let homeVC = self.toVC as? HomeViewController else { return }

        let containerView = transitionContext.containerView
        containerView.addSubview(self.toVC.view)
        containerView.set(backgroundColor: fromColor)

        let toVCFinalFrame = transitionContext.finalFrame(for: self.toVC)
        self.toVC.view.frame = toVCFinalFrame

        self.toVC.view.layoutIfNeeded()

        let transformOffset = homeVC.tabView.height
        self.toVC.navigationController?.navigationBar.alpha = 0
        self.toVC.view.frame = toVCFinalFrame
        self.toVC.view.alpha = 0
        homeVC.centerContainer.transform = CGAffineTransform(translationX: 0, y: transformOffset)

        self.toVC.navigationController?.navigationBar.alpha = 0

        UIView.animateKeyframes(withDuration: self.transitionDuration(using: transitionContext),
                                delay: 0,
                                options: .calculationModeCubicPaced,
                                animations: {

                                    // Fade out the fromVC
                                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                                        self.fromVC.view.transform = CGAffineTransform(scaleX: 0, y: transformOffset)
                                        self.fromVC.view.alpha = 0
                                        self.fromVC.navigationController?.navigationBar.alpha = 0
                                        containerView.set(backgroundColor: self.toVC.transitionColor)
                                        self.toVC.view.alpha = 1
                                        self.toVC.navigationController?.navigationBar.alpha = 1
                                    }

                                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                                        homeVC.centerContainer.transform = .identity
                                    }
        }) { (completed) in
            // Unhide all of the views we tampered with so that they're visible after the transition
            self.fromVC.view.alpha = 1
            self.fromVC.view.transform = .identity
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
#endif
