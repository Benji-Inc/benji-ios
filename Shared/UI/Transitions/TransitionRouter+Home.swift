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

        self.toVC.navigationController?.navigationBar.alpha = 0
        self.toVC.view.frame = toVCFinalFrame
        self.toVC.view.alpha = 0

        self.toVC.navigationController?.navigationBar.alpha = 0

        UIView.animateKeyframes(withDuration: self.transitionDuration(using: transitionContext),
                                delay: 0,
                                options: .calculationModeLinear,
                                animations: {

                                    // Fade out the fromVC
                                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                                        self.fromVC.view.alpha = 0
                                        self.fromVC.navigationController?.navigationBar.alpha = 0
                                        containerView.set(backgroundColor: self.toVC.transitionColor)
                                    }

                                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                                        self.toVC.view.alpha = 1
                                        self.toVC.navigationController?.navigationBar.alpha = 1
                                    }
        }) { (completed) in
            // Unhide all of the views we tampered with so that they're visible after the transition
            self.fromVC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
#endif
