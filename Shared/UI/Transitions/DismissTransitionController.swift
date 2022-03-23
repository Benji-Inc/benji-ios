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

        guard let rootVC = transitionContext.viewController(forKey: .to) as? RootNavigationController,
              let listVC = rootVC.viewControllers.first(where: { controller in
                  return controller is ConversationListViewController
              }) as? ConversationListViewController,
              let interactableVC = transitionContext.viewController(forKey: .from) as? MessageInteractableController
               else { return }

        let fromView = interactableVC.messageContent
        let toView = listVC.getCentmostMessageCellContent()!

        let containerView = transitionContext.containerView

        containerView.addSubview(interactableVC.view)

        let finalFrame = toView.convert(toView.bounds, to: containerView)

        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext),
                                              curve: .linear)

        let threadVC = interactableVC as? ThreadViewController
        
        animator.addAnimations {

            UIView.animateKeyframes(withDuration: 0.0, delay: 0.0, animations: {

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                    fromView.center = finalFrame.center
                    interactableVC.handleDismissal()
                }

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                    interactableVC.handleInitialDismissal()
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7) {
                    interactableVC.blurView.showBlur(false)
                }
              })
        }

        animator.addCompletion { (position) in
            if position == .end {
                toView.isHidden = false
                fromView.isHidden = true
                delay(0.1) {
                    listVC.becomeFirstResponder()
                }
            } else if position == .start {
                toView.isHidden = true
                fromView.isHidden = false
            }

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        self.animator = animator
    }
}

