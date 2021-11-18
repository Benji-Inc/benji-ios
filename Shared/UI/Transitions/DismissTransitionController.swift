//
//  DismissTransitionController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// This class is used to handle custom dismiss transitions for CardTransitionableControllers that are presented modally
class DismissTransitionController: NSObject, UIViewControllerAnimatedTransitioning {

    let toVC: ViewController
    let fromVC: ViewController

    let interactionController: PanDismissInteractionController?

    var animator: UIViewPropertyAnimator!

    init(toVC: ViewController,
         fromVC: ViewController,
         interactionController: PanDismissInteractionController?) {

        self.toVC = toVC
        self.fromVC = fromVC
        self.interactionController = interactionController

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Theme.animationDurationStandard
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.createAnimator(using: transitionContext)
        self.animator.startAnimation()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        self.createAnimator(using: transitionContext)
        return self.animator
    }

    private func createAnimator(using transitionContext: UIViewControllerContextTransitioning) {

        guard self.animator == nil else {
            return
        }

//        let dismissingVC = transitionContext.viewController(forKey: .from)!
//        let presentingVC = transitionContext.viewController(forKey: .to)!
//
//        let containerView = transitionContext.containerView
//
//        containerView.addSubview(presentingVC.view)
//
//        // Add the blur view above the VC we're going to so it gradually becomes sharper
//        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
//        blurView.frame = containerView.bounds
//        containerView.addSubview(blurView)
//
//        containerView.addSubview(dismissingVC.view)
//
//        // Setup temp transition view for animation
//        let initialFrame = containerView.convert(self.fromVC.transitionableView.bounds,
//                                                      from: self.fromVC.transitionableView)
//        let finalFrame = containerView.convert(self.toVC.transitionableView.bounds,
//                                               from: self.toVC.transitionableView)
//
//        let toTransitionableSnapshot = self.toVC.transitionableView.snapshotView(afterScreenUpdates: true)!
//        containerView.addSubview(toTransitionableSnapshot)
//        toTransitionableSnapshot.frame = initialFrame
//
//        // Transition view intitialization
//        let transitionView = CardTransitionalView(with: currentModel)
//        containerView.addSubview(transitionView)
//
//        transitionView.frame = initialFrame
//        transitionView.layoutNow()

        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext),
                                              curve: .easeOut)

        animator.addAnimations { [unowned self] in
            UIView.animateKeyframes(withDuration: 0,
                                    delay: 0,
                                    animations: {

                                        // Hiding the transitionable views of the to and from VC
                                        UIView.addKeyframe(withRelativeStartTime: 0,
                                                           relativeDuration: 0,
                                                           animations: {
//                                                            self.fromVC.transitionableView.alpha = 0
//                                                            self.toVC.transitionableView.alpha = 0
                                        })

                                        UIView.addKeyframe(withRelativeStartTime: 0,
                                                           relativeDuration: 0.01,
                                                           animations: {
                                                            //transitionView.layer.cornerRadius = 0
                                        })

                                        UIView.addKeyframe(withRelativeStartTime: 0,
                                                           relativeDuration: 0.3,
                                                           animations: {
                                                            //dismissingVC.view.alpha = 0
                                        })

                                        UIView.addKeyframe(withRelativeStartTime: 0,
                                                           relativeDuration: 0.7,
                                                           animations: {
//                                                            blurView.effect = nil
//                                                            transitionView.handleTransition(for: destinationModel)
//                                                            transitionView.frame = finalFrame
//                                                            transitionView.layer.cornerRadius = TomorrowTheme.roundedRadius
//                                                            transitionView.layoutNow()
//                                                            toTransitionableSnapshot.frame = finalFrame
                                        })

                                        UIView.addKeyframe(withRelativeStartTime: 0.7,
                                                           relativeDuration: 0.3,
                                                           animations: {
                                                            //self.toVC.transitionableView.alpha = 1
                                                           // transitionView.handlePresentation(for: destinationModel)
                                                           // transitionView.alpha = 0
                                        })
            })
        }

        animator.addCompletion { [unowned self] (position) in
            //blurView.removeFromSuperview()
            //transitionView.removeFromSuperview()

            //toTransitionableSnapshot.removeFromSuperview()
            //self.toVC.transitionableView.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        self.animator = animator
    }
}

