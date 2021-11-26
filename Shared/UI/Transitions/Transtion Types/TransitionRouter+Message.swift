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
            snapshot.configure(with: message)
            snapshot.backgroundColorView.bubbleColor = fromView.backgroundColorView.bubbleColor
            snapshot.backgroundColorView.tailLength = 0
            snapshot.backgroundColorView.orientation = fromView.backgroundColorView.orientation

            toView.configure(with: message)
            toView.backgroundColorView.bubbleColor = Color.white.color
            toView.backgroundColorView.tailLength = 0
            toView.backgroundColorView.orientation = fromView.backgroundColorView.orientation
            toView.size = fromView.size
            toView.layoutNow()
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

        Task {
            await UIView.awaitSpringAnimation(with: .slow, animations: {
                snapshot.frame = finalFrame
                snapshot.backgroundColorView.bubbleColor = Color.white.color
                threadVC.blurView.showBlur(true)
                self.toVC.view.alpha = 1
            })
            toView.alpha = 1
            snapshot.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }.add(to: self.taskPool)
    }

    private func dismissThread(fromView: MessageContentView,
                               toView: MessageContentView,
                               transitionContext: UIViewControllerContextTransitioning) {

        guard let threadVC = self.fromVC as? ThreadViewController,
              let listVC = self.toVC as? ConversationListViewController else { return }

        // Make sure we have all the components we need to complete this transition
        let snapshot = MessageContentView()

        if let message = fromView.message {
            snapshot.configure(with: message)
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

        Task {
            await UIView.awaitSpringAnimation(with: .slow, animations: {
                threadVC.blurView.showBlur(false)
                self.fromVC.view.alpha = 0
                snapshot.frame = finalFrame
                snapshot.backgroundColorView.bubbleColor = toView.backgroundColorView.bubbleColor
            })
            toView.isHidden = false
            snapshot.removeFromSuperview()
            delay(0.1) {
                listVC.becomeFirstResponder()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }.add(to: self.taskPool)
    }
}
