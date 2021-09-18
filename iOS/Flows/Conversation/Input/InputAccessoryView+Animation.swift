//
//  MessageInputAccessoryView+Animation.swift
//  Benji
//
//  Created by Benji Dodgson on 6/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension InputAccessoryView {

    func handle(longPress: UILongPressGestureRecognizer) {

        switch longPress.state {
        case .possible:
            break
        case .began:
            if case MessageKind.text(let text) = self.currentMessageKind, text.isEmpty {
                UIMenuController.shared.showMenu(from: self, rect: self.textView.bounds)
            } else {
                self.startAlertAnimation()
            }
        case .changed:
            break
        case .ended, .cancelled, .failed:
            if case MessageKind.text(let text) = self.currentMessageKind, text.isEmpty {
                break
            } else {
                self.endAlertAnimation()
            }
        @unknown default:
            break
        }
    }

    private func startAlertAnimation() {
        self.currentContext = .timeSensitive
        self.alertAnimator?.stopAnimation(true)
        self.alertAnimator?.pausesOnCompletion = true
        self.selectionFeedback.impactOccurred()

        self.alertAnimator = UIViewPropertyAnimator(duration: 1.0,
                                                    curve: .linear,
                                                    animations: { [unowned self] in
            self.alertProgressView.size = CGSize(width: self.width, height: self.height)
        })

        self.alertAnimator?.startAnimation()

        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseIn, .repeat, .autoreverse], animations: {
            self.alertProgressView.alpha = 0
            self.selectionFeedback.impactOccurred()
        }, completion: nil)
    }

    private func endAlertAnimation() {
        if let fractionComplete = self.alertAnimator?.fractionComplete,
            fractionComplete == CGFloat(0.0) {

            self.alertAnimator?.stopAnimation(true)
            self.showAlertConfirmation()
        } else {
            self.alertAnimator?.stopAnimation(true)
            self.currentContext = .passive
            self.alertAnimator = UIViewPropertyAnimator(duration: 0.5,
                                                        curve: .linear,
                                                        animations: { [unowned self] in
                                                            self.alertProgressView.size = CGSize(width: 0, height: self.height)
                                                            self.layer.borderColor = self.currentContext.color.color.cgColor
            })
            self.alertAnimator?.startAnimation()
        }
    }

    private func showAlertConfirmation() {
        #warning("Replace")
//        guard let c = self.activeConversation, case Conversation.conversation = c.conversationType else { return }
//
//        self.textView.updateInputView(type: .confirmation)
//
//        let members = conversation.getNonMeMembers()
//        self.textView.confirmationView.setAlertMessage(for: members)
//
//        self.alertProgressView.size = CGSize(width: self.width, height: self.height)
    }
}
