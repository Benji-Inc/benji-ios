//
//  DismissTransitionController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// This class is used to handle custom dismiss transitions for DismissTransitionController that are presented modally
class DismissTransitionController: NSObject, UIViewControllerAnimatedTransitioning {

    let interactionController: PanDismissInteractionController?

    var animator: UIViewPropertyAnimator?

    init(interactionController: PanDismissInteractionController?) {

        self.interactionController = interactionController

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Theme.animationDurationStandard
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.createAnimator(using: transitionContext)
        self.animator?.startAnimation()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let animator = self.animator {
            return animator 
        } else {
            self.createAnimator(using: transitionContext)
            return self.animator!
        }
    }

    private func createAnimator(using transitionContext: UIViewControllerContextTransitioning) {

        guard self.animator.isNil else {
            return
        }
        
        var toVC: MessageInteractableController?
        var toView: MessageContentView?
        var fromView: MessageContentView?
        var fromVC: MessageInteractableController?
        
        if let vc = transitionContext.viewController(forKey: .to) as? MessageInteractableController {
            toVC = vc
            toView = vc.messageContent
        } else if let rootVC = transitionContext.viewController(forKey: .to) as? RootNavigationController,
                  let listVC = rootVC.viewControllers.first(where: { controller in
                      return controller is ConversationViewController
                  }) as? ConversationViewController {
            toVC = listVC
            toView = listVC.messageContent
        }
        
        if let vc = transitionContext.viewController(forKey: .from) as? MessageInteractableController {
            fromVC = vc
            fromView = vc.messageContent
        }
        
        guard let toView = toView,
              let fromView = fromView,
              let fromVC = fromVC else { return }


        let containerView = transitionContext.containerView

        containerView.addSubview(fromVC.view)

        let finalFrame = toView.convert(toView.bounds, to: containerView)

        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext),
                                              curve: .linear)
        
        animator.addAnimations {

            UIView.animateKeyframes(withDuration: 0.0, delay: 0.0, animations: {

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                    fromView.center = finalFrame.center
                    fromVC.handleDismissal()
                }

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                    fromVC.handleInitialDismissal()
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                    fromVC.blurView.showBlur(false)
                }
              })
        }

        animator.addCompletion { (position) in
            if position == .end {
                toView.isHidden = false
                toVC?.handleCompletedDismissal()
            } else if position == .start {
                toView.isHidden = true
            }

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        self.animator = animator
    }
}

