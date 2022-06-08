//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import UIKit

/// This class is used to handle custom present transitions for CardTransitionableControllers that are presented modally
open class TransitioningController: NSObject, UIViewControllerTransitioningDelegate {
    
    open func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let from = source as? TransitionableViewController,
           let toVC = presented as? TransitionableViewController {
            switch toVC.presentationType {
            case .modal:
                return nil
            default:
                toVC.fromTransitionController = from
                return self.getRouter(fromVC: from, toVC: toVC, operation: .push)
            }
        } else {
            return nil
        }
    }
    
    open func getRouter(fromVC: TransitionableViewController,
                        toVC: TransitionableViewController,
                        operation: UINavigationController.Operation) -> TransitionableRouter {
        return TransitionableRouter(fromVC: fromVC, toVC: toVC, operation: operation)
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Reverse the vc's to go back
        if let from = dismissed as? TransitionableViewController, let to = from.fromTransitionController {
            return self.getRouter(fromVC: from, toVC: to, operation: .pop)
        } else {
            return nil
        }
    }
    
    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}

private var presentingTransitionControllerHandle: UInt = 0
// We need to remember which VC presents a UIViewController so that we can properly
// run the dismiss animation. This private extension allows us to do that without forcing
// transitionableVCs to provide their own member var.
private extension UIViewController {
    
    /// The transitionable view controller that presented this view controller.
    var presentingTransitionController: UIViewController? {
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
extension TransitionableViewController {
    
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
