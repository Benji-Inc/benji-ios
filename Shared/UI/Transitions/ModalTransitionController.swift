//
//  ModalTransitionRouter.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol DismissInteractableController where Self: ViewController {
    var dismissInteractionController: PanDismissInteractionController { get }
}

/// This class is used to handle custom present transitions for CardTransitionableControllers that are presented modally
class ModalTransitionController: NSObject, UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if let from = source as? TransitionableViewController,
            let toVC = presented as? TransitionableViewController {

            // If there is a parent it will crash on dismiss.
            //if from.parent.isNil {
                toVC.fromTransitionController = from
            //}
            return TransitionRouter(fromVC: from, toVC: toVC, operation: .push)
        } else {
            return nil
        }
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        // Reverse the vc's to go back
        if let fromVC = dismissed as? DismissInteractableController,
            let toVC = fromVC.presentingTransitionController {

            var interactionController: PanDismissInteractionController?
            if fromVC.dismissInteractionController.interactionInProgress {
                interactionController = fromVC.dismissInteractionController
            }

            return DismissTransitionController(toVC: toVC,
                                               fromVC: fromVC,
                                               interactionController: interactionController)

        } else if let from = dismissed as? TransitionableViewController, let to = from.fromTransitionController {
            return TransitionRouter(fromVC: from, toVC: to, operation: .pop)
        } else {
            return nil
        }
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {

        guard let transitionController = animator as? DismissTransitionController else { return nil }

        return transitionController.interactionController
    }
}

private var presentingTransitionControllerHandle: UInt = 0
// We need to remember which VC presents a CardTransitionableController so that we can properly
// run the dismiss animation. This private extension allows us to do that without forcing
// transitionableVCs to provide their own member var.
private extension ViewController {

    /// The transitionable view controller that presented this view controller.
    var presentingTransitionController: ViewController? {
        get {
            return getAssociatedObject(&presentingTransitionControllerHandle)
        }

        set {
            self.setAssociatedObject(key: &presentingTransitionControllerHandle,
                                     value: newValue,
                                     policy: .OBJC_ASSOCIATION_ASSIGN)  // Weak ref prevents memory leaks
        }
    }
}

private var transitionControllerHandle: UInt = 0
// We need to remember which VC presents a CardTransitionableController so that we can properly
// run the dismiss animation. This private extension allows us to do that without forcing
// transitionableVCs to provide their own member var.
private extension TransitionableViewController {

    /// The transitionable view controller that presented this view controller.
    var fromTransitionController: TransitionableViewController?  {
        get {
            return self.getAssociatedObject(&transitionControllerHandle)
        }
        set {
            self.setAssociatedObject(key: &transitionControllerHandle, value: newValue)
        }
    }
}
