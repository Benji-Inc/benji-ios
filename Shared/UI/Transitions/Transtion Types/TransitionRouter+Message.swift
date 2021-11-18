//
//  TransitionRouter+Message.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension TransitionRouter {

    func messageTranstion(fromView: MessageContentView,
                          toView: MessageContentView,
                          transitionContext: UIViewControllerContextTransitioning) {

        if self.toVC is ThreadViewController {
            self.presentThread(fromView: fromView, toView: toView, transitionContext: transitionContext)
        } else {
            self.dismissThread(fromView: fromView, toView: toView, transitionContext: transitionContext)
        }
    }

    private func presentThread(fromView: MessageContentView,
                               toView: MessageContentView,
                               transitionContext: UIViewControllerContextTransitioning) {

        guard let threadVC = self.toVC as? ThreadViewController,
              let listVC = self.fromVC as? ConversationListViewController else { return }

        // Make sure we have all the components we need to complete this transition
        guard let snapshot = fromView.snapshotView(afterScreenUpdates: false) else {
            return
        }

        let containerView = transitionContext.containerView
        containerView.set(backgroundColor: .clear)
        fromView.isHidden = true

        let toVCFinalFrame = transitionContext.finalFrame(for: threadVC)
        threadVC.view.frame = toVCFinalFrame

        containerView.addSubview(threadVC.view)
        threadVC.view.layoutIfNeeded()

        containerView.addSubview(snapshot)
        let finalFrame = toView.convert(toView.bounds, to: containerView)

        //self.toVC.view.frame = toVCFinalFrame
        threadVC.view.alpha = 0
        threadVC.blurView.showBlur(false)

        // Put snapshot in the exact same spot as the original so that the transition looks seamless
        snapshot.frame = fromView.convert(fromView.bounds, to: containerView)

        toView.alpha = 0
        //fromView.alpha = 0
        //self.toVC.navigationController?.navigationBar.alpha = 0

        let moveDuration = self.transitionDuration(using: transitionContext) * 0.65

        // Broke this out to get the timing curve to work.
        UIView.animate(withDuration: moveDuration,
                       delay: 0.0,
                       options: .curveEaseInOut,
                       animations: {
            snapshot.frame = finalFrame
        }) { (_) in}

        UIView.animateKeyframes(withDuration: self.transitionDuration(using: transitionContext),
                                delay: 0,
                                options: .calculationModeLinear,
                                animations: {

            // Apply blurr
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.65) {
                // listVC.view.alpha = 0
                threadVC.blurView.showBlur(true)
                self.toVC.view.alpha = 1
            }

            // Fade in view of toVC
            UIView.addKeyframe(withRelativeStartTime: 0.65, relativeDuration: 0.35) {
                toView.alpha = 1
            }
        }) { (completed) in
            snapshot.removeFromSuperview()
            fromView.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func dismissThread(fromView: MessageContentView,
                               toView: MessageContentView,
                               transitionContext: UIViewControllerContextTransitioning) {

        guard let threadVC = self.fromVC as? ThreadViewController,
              let listVC = self.toVC as? ConversationListController else { return }

    }
}
