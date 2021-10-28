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

    override func initializeSubviews() {
        super.initializeSubviews()

        self.currentContext = .passive

        self.inputContainerView.insertSubview(self.alertProgressView, belowSubview: self.textView)
        self.alertProgressView.set(backgroundColor: .white)
        self.alertProgressView.size = .zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.alertProgressView.height = self.inputContainerView.height
    }

    // MARK: SETUP

    override func setupGestures() {
        super.setupGestures()

        let longPressRecognizer = UILongPressGestureRecognizer { [unowned self] (recognizer) in
            self.handle(longPress: recognizer)
        }
        longPressRecognizer.delegate = self
        self.overlayButton.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: OVERRIDES

    override func updateInputType() {
        super.updateInputType()
//
//        // If keyboard, then show attachments
//        // If attachments & currentKind != .text, Then still show x
//        // If progess is greater than 0 and pressed, reset attachment view.
//        let currentType = self.textView.currentInputView
//        let currentProgress = self.plusAnimationView.currentProgress
//
//        if currentType == .keyboard {
//            if self.attachmentView.attachment.isNil {
//                let newType: InputViewType = .attachments
//                self.textView.updateInputView(type: newType)
//            } else {
//                self.attachmentView.configure(with: nil)
//            }
//
//            let toProgress: CGFloat = currentProgress == 0 ? 1.0 : 0.0
//            self.plusAnimationView.play(fromProgress: currentProgress, toProgress: toProgress, loopMode: .playOnce, completion: nil)
//
//        } else if currentProgress > 0 {
//
//            let newType: InputViewType = .keyboard
//
//            if self.attachmentView.attachment.isNil {
//                let toProgress: CGFloat = currentProgress == 0 ? 1.0 : 0.0
//                self.plusAnimationView.play(fromProgress: currentProgress, toProgress: toProgress, loopMode: .playOnce, completion: nil)
//            }
//            self.textView.updateInputView(type: newType)
//
//        } else {
//            // progress is greater that 0 and input type is attachments
//            self.attachmentView.messageKind = nil
//        }
    }

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
