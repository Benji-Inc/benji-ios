//
//  ModalTransitionRouter.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Transitions
import UIKit

class ModalTransitionController: TransitioningController {

    override func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        // Reverse the vc's to go back
        #if IOS
        if let fromVC = dismissed as? DismissInteractableController,
            let interactionController = fromVC.dismissInteractionController,
            interactionController.interactionInProgress {

            return DismissTransitionController(interactionController: interactionController)
        }
        #endif
        
        return super.animationController(forDismissed: dismissed)
    }
    
    override func getRouter(fromVC: TransitionableViewController, toVC: TransitionableViewController, operation: UINavigationController.Operation) -> TransitionableRouter {
        return TransitionRouter(fromVC: fromVC, toVC: toVC, operation: operation)
    }

    override func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? {

        #if IOS
        guard let transitionController = animator as? DismissTransitionController else { return nil }
        return transitionController.interactionController
        #else
        return super.interactionControllerForDismissal(using: animator)
        #endif
    }
}
