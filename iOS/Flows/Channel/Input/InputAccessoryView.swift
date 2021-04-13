//
//  MessageInputAccessoryView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/2/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import TMROLocalization
import Combine

typealias InputAccessoryDelegates = MessageInputAccessoryViewDelegate

protocol MessageInputAccessoryViewDelegate: AnyObject {
    func inputAccessory(_ view: InputAccessoryView, didConfirm sendable: Sendable)
}

class InputAccessoryView: SwipeableInputAccessoryView, ActiveChannelAccessor {

    var currentContext: MessageContext = .casual {
        didSet {
            self.borderColor = self.currentContext.color.color.cgColor
        }
    }
    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    let alertProgressView = AlertProgressView()
    private var sendableObject: SendableObject?

    override var borderColor: CGColor? {
        didSet {
            self.inputContainerView.layer.borderColor = self.borderColor ?? self.currentContext.color.color.cgColor
        }
    }

    unowned let delegate: InputAccessoryDelegates

    init(with delegate: InputAccessoryDelegates) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.currentContext = .casual

        self.inputContainerView.insertSubview(self.alertProgressView, belowSubview: self.textView)
        self.alertProgressView.set(backgroundColor: .red)
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

    override func attachentViewDidUpdate(kind: MessageKind?) {
        super.attachentViewDidUpdate(kind: kind)

        self.currentMessageKind = kind ?? .text(String())
        self.textView.setPlaceholder(for: self.currentMessageKind)
    }

    override func handleTextChange(_ text: String) {
        super.handleTextChange(text)

        switch self.currentMessageKind {
        case .text(_):
            self.currentMessageKind = .text(text)
        case .photo(photo: let photo, _):
            self.currentMessageKind = .photo(photo: photo, body: text)
        case .video(video: let video, _):
            self.currentMessageKind = .video(video: video, body: text)
        default:
            break
        }

        guard let channelDisplayable = self.activeChannel,
            text.count > 0,
            case ChannelType.channel(let channel) = channelDisplayable.channelType else { return }
        // Twilio throttles this call to every 5 seconds
        channel.typing()
    }

    override func updateInputType() {
        super.updateInputType()

        // If keyboard, then show attachments
        // If attachments & currentKind != .text, Then still show x
        // If progess is greater than 0 and pressed, reset attachment view.

        let currentType = self.textView.currentInputView
        let currentProgress = self.plusAnimationView.currentProgress

        if currentType == .keyboard {
            if self.attachmentView.attachment.isNil {
                let newType: InputViewType = .attachments
                self.textView.updateInputView(type: newType)
            } else {
                self.attachmentView.configure(with: nil)
            }

            let toProgress: CGFloat = currentProgress == 0 ? 1.0 : 0.0
            self.plusAnimationView.play(fromProgress: currentProgress, toProgress: toProgress, loopMode: .playOnce, completion: nil)

        } else if currentProgress > 0 {

            let newType: InputViewType = .keyboard

            if self.attachmentView.attachment.isNil {
                let toProgress: CGFloat = currentProgress == 0 ? 1.0 : 0.0
                self.plusAnimationView.play(fromProgress: currentProgress, toProgress: toProgress, loopMode: .playOnce, completion: nil)
            }
            self.textView.updateInputView(type: newType)

        } else {
            // progress is greater that 0 and input type is attachments
            self.attachmentView.messageKind = nil
        }
    }

    override func animateInputViews(with text: String) {
        super.animateInputViews(with: text)

        let inputOffset: CGFloat
        if text.count > 0 {
            inputOffset = 0
        } else {
            inputOffset = 53
        }

        guard let constraint = self.inputLeadingContstaint, inputOffset != constraint.constant else { return }

        UIView.animate(withDuration: Theme.animationDuration) {
            self.plusAnimationView.transform = inputOffset == 0 ? CGAffineTransform(scaleX: 0.5, y: 0.5) : .identity
            self.plusAnimationView.alpha = inputOffset == 0 ? 0.0 : 1.0
            self.inputLeadingContstaint?.constant = inputOffset
            self.layoutNow()
        }
    }

    override func shouldHandlePan() -> Bool {
        let object = SendableObject(kind: self.currentMessageKind, context: self.currentContext, previousMessage: self.editableMessage)
        self.sendableObject = object
        return object.isSendable
    }

    override func panDidBegin() {
        super.panDidBegin()

        self.previewView?.set(backgroundColor: self.currentContext.color)
        self.previewView?.messageKind = self.currentMessageKind
    }

    override func previewAnimatorDidEnd() {
        super.previewAnimatorDidEnd()

        if let object = self.sendableObject {
            self.delegate.inputAccessory(self, didConfirm: object)
        }

        self.sendableObject = nil 
    }

    override func attachementView(_ controller: AttachmentViewController, didSelect attachment: Attachment) {
        super.attachementView(controller, didSelect: attachment)

        self.attachmentView.configure(with: attachment)
        self.updateInputType() // Needs to be called after configure
    }

    override func didPressAlertCancel() {
        super.didPressAlertCancel()

        self.resetAlertProgress()
    }

    override func reset() {
        super.reset()
        self.resetAlertProgress()
    }

    // MARK: PUBLIC

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
        self.currentContext = .casual
        self.alertProgressView.width = 0
        self.alertProgressView.set(backgroundColor: .red)
        self.alertProgressView.alpha = 1
        self.alertProgressView.layer.removeAllAnimations()
        self.textView.updateInputView(type: .keyboard)
    }
}

class AlertProgressView: View {}
