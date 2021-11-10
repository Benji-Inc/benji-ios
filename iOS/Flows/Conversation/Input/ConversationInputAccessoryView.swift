//
//  InputAccessoryView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/2/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import TMROLocalization
import Combine
import GestureRecognizerClosures
import StreamChat

class ConversationInputAccessoryView: SwipeableInputAccessoryView {

    let alertProgressView = AlertProgressView()
    var alertAnimator: UIViewPropertyAnimator?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.currentContext = .passive

        self.inputContainerView.insertSubview(self.alertProgressView, belowSubview: self.textView)
        self.alertProgressView.set(backgroundColor: .lightGray)
        self.alertProgressView.size = .zero
        self.alertProgressView.roundCorners()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.alertProgressView.height = self.inputContainerView.bubbleFrame.height
    }

    // MARK: SETUP

    override func setupGestures() {
        super.setupGestures()

        // Disabling the time sensitive interaction for now
//        let longPressRecognizer = UILongPressGestureRecognizer { [unowned self] (recognizer) in
//            self.handle(longPress: recognizer)
//        }
//        longPressRecognizer.delegate = self
//        self.overlayButton.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: OVERRIDES

    override func didPressAlertCancel() {
        super.didPressAlertCancel()

        self.resetAlertProgress()
    }

    override func resetInputViews() {
        super.resetInputViews()
        self.resetAlertProgress()
    }

    // MARK: PUBLIC

    func updateTypingActivity(with users: Set<ChatUser>) {
        var text: String = ""
        var names: [String] = []
        for (index, user) in users.enumerated() {
            if users.count == 1 || index == users.count - 1 {
                text.append("\(user.givenName) is typing...")
            } else {
                text.append("\(user.givenName), ")
            }

            names.append(user.givenName)
        }

        self.activityBar.update(text: text, with: names)
    }

    func edit(message: Messageable) {
        switch message.kind {
        case .text(let body):
            self.textView.text = body
        case .attributedText(let body):
            self.textView.text = body.string
        case .photo(photo: _, body: let body):
            self.textView.text = body
        case .video(video: _, body: let body):
            self.textView.text = body
        default:
            return
        }

        self.currentContext = message.context
        self.currentMessageKind = message.kind
        self.editableMessage = message

        self.textView.becomeFirstResponder()
    }

    func resetAlertProgress() {
        self.currentContext = .passive
        self.alertProgressView.width = 0
        self.alertProgressView.set(backgroundColor: .white)
        self.alertProgressView.alpha = 1
        self.alertProgressView.layer.removeAllAnimations()
        self.textView.updateInputView(type: .keyboard)
    }
}

class AlertProgressView: View {}

extension ConversationInputAccessoryView {

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
        self.impactFeedback.impactOccurred()

        self.alertAnimator = UIViewPropertyAnimator(duration: 1.0,
                                                    curve: .linear,
                                                    animations: { [unowned self] in
            self.alertProgressView.size = CGSize(width: self.textView.width,
                                                 height: self.textView.height)
        })

        self.alertAnimator?.startAnimation()

        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseIn, .repeat, .autoreverse], animations: {
            self.alertProgressView.alpha = 0
            self.impactFeedback.impactOccurred()
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
