//
//  TransitionRouter.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

/// A custom transitions that simultaneously slides the current VC vertically off the screen
/// and the destination one onto it.
class TransitionRouter: NSObject, UIViewControllerAnimatedTransitioning {

    // The fromVC sets the stage for how it wants to get to the toVC
    private(set) var fromVC: TransitionableViewController
    private(set) var toVC: TransitionableViewController
    let operation: UINavigationController.Operation

    let taskPool = TaskPool()

    init(fromVC: TransitionableViewController,
         toVC: TransitionableViewController,
         operation: UINavigationController.Operation) {

        self.fromVC = fromVC
        self.toVC = toVC
        self.operation = operation

        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let isPresenting = self.operation == .push
        if isPresenting {
            return self.toVC.toVCPresentationType.duration
        } else {
            return self.fromVC.fromVCDismissalType.duration
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresenting = self.operation == .push

        let presentedVCTransition: TransitionType
        let presentingVCTransition: TransitionType
        if isPresenting {
            presentedVCTransition = self.toVC.toVCPresentationType
            presentingVCTransition = self.fromVC.getFromVCPresentationType(for: presentedVCTransition)
        } else {
            presentedVCTransition = self.fromVC.fromVCDismissalType
            presentingVCTransition = self.toVC.getToVCDismissalType(for: presentedVCTransition)
        }


        switch presentedVCTransition {
        case .move(let presentedView):
            // A move transition required that both VCs support the move style.
            // If one does not, fall back to a cross dissolve animation.
            switch presentingVCTransition {
            case .move(let presentingView):
                if isPresenting {
                    self.moveTranstion(fromView: presentingView,
                                       toView: presentedView,
                                       transitionContext: transitionContext)
                } else {
                    self.moveTranstion(fromView: presentedView,
                                       toView: presentingView,
                                       transitionContext: transitionContext)
                }
            default:
                self.crossDissolveTransition(transitionContext: transitionContext)
            }
        case .fadeOutIn:
            self.fadeTransition(transitionContext: transitionContext)
        case .crossDissolve:
            self.crossDissolveTransition(transitionContext: transitionContext)
        case .fill(let expandingView):
            self.fillTranstion(expandingView: expandingView, transitionContext: transitionContext)
        case .blur:
            self.blur(transitionContext: transitionContext)
#if IOS
        case .message(let presentedView):
            // Message transitions require that both VCs support the message transition style.
            // If one doesn't, then fallback to cross dissolve.
            switch presentingVCTransition {
            case .message(let presentingView):
                if isPresenting {
                    self.messageTranstion(fromView: presentingView,
                                          toView: presentedView,
                                          transitionContext: transitionContext)
                } else {
                    self.messageTranstion(fromView: presentedView,
                                          toView: presentingView,
                                          transitionContext: transitionContext)
                }
            default:
                self.crossDissolveTransition(transitionContext: transitionContext)
            }
#endif
        }
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.taskPool.cancelAndRemoveAll()
    }
}
