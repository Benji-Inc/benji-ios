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

        guard let threadVC = self.toVC as? ThreadViewController else { return }

        // Make sure we have all the components we need to complete this transition
        let snapshot = MessageContentView()

        if let message = fromView.message {
            snapshot.setText(with: message)

            snapshot.backgroundColorView.bubbleColor = fromView.backgroundColorView.bubbleColor
            snapshot.backgroundColorView.tailLength = fromView.backgroundColorView.tailLength
            snapshot.backgroundColorView.orientation = fromView.backgroundColorView.orientation

            toView.setText(with: message)
            toView.backgroundColorView.bubbleColor = fromView.backgroundColorView.bubbleColor
            toView.backgroundColorView.tailLength = fromView.backgroundColorView.tailLength
            toView.backgroundColorView.orientation = fromView.backgroundColorView.orientation
            toView.size = fromView.size
        }

        snapshot.frame = fromView.frame

        let containerView = transitionContext.containerView
        containerView.set(backgroundColor: .clear)
        fromView.isHidden = true

        let toVCFinalFrame = transitionContext.finalFrame(for: threadVC)
        threadVC.view.frame = toVCFinalFrame

        containerView.addSubview(threadVC.view)
        threadVC.view.layoutIfNeeded()

        containerView.addSubview(snapshot)
        let finalFrame = toView.convert(toView.bounds, to: containerView)

        threadVC.view.alpha = 0
        threadVC.blurView.showBlur(false)

        // Put snapshot in the exact same spot as the original so that the transition looks seamless
        snapshot.frame = fromView.convert(fromView.bounds, to: containerView)

        toView.alpha = 0

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 1,
                       options: .curveEaseInOut,
                       animations: {
            snapshot.frame = finalFrame
            threadVC.blurView.showBlur(true)
            self.toVC.view.alpha = 1

        }) { _ in
            toView.alpha = 1
            snapshot.removeFromSuperview()
            fromView.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func dismissThread(fromView: MessageContentView,
                               toView: MessageContentView,
                               transitionContext: UIViewControllerContextTransitioning) {

        guard let threadVC = self.fromVC as? ThreadViewController,
              let listVC = self.toVC as? ConversationListViewController else { return }

        // Make sure we have all the components we need to complete this transition
        let snapshot = MessageContentView()

        if let message = fromView.message {
            snapshot.setText(with: message)
            snapshot.backgroundColorView.bubbleColor = fromView.backgroundColorView.bubbleColor
            snapshot.backgroundColorView.tailLength = fromView.backgroundColorView.tailLength
            snapshot.backgroundColorView.orientation = fromView.backgroundColorView.orientation
        }

        snapshot.frame = fromView.frame

        let containerView = transitionContext.containerView
        containerView.set(backgroundColor: .clear)
        fromView.isHidden = true

        containerView.addSubview(snapshot)
        let finalFrame = toView.convert(toView.bounds, to: containerView)

        // Put snapshot in the exact same spot as the original so that the transition looks seamless
        snapshot.frame = fromView.convert(fromView.bounds, to: containerView)

        toView.alpha = 0

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 1,
                       options: .curveEaseIn,
                       animations: {
            threadVC.blurView.showBlur(false)
            self.fromVC.view.alpha = 0
            snapshot.frame = finalFrame
        }) { _ in
            toView.alpha = 1
            snapshot.removeFromSuperview()
            fromView.isHidden = true
            delay(0.1) {
                listVC.becomeFirstResponder()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
