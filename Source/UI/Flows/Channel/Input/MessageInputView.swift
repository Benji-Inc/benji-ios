//
//  MessageInputView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

class MessageInputView: View, ActiveChannelAccessor {

    var onPanned: ((UIPanGestureRecognizer) -> Void)?

    private(set) var minHeight: CGFloat = 44
    var oldTextViewHeight: CGFloat = 44

    let textView = InputTextView()
    let overlayButton = UIButton()
    private let alertProgressView = AlertProgressView()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private lazy var alertConfirmation = AlertConfirmationView()
    private lazy var countView = CharacterCountView()

    private var alertAnimator: UIViewPropertyAnimator?
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .rigid)

    private(set) var messageContext: MessageContext = .casual

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .backgroundWithAlpha)

        self.addSubview(self.blurView)
        self.addSubview(self.alertProgressView)
        self.alertProgressView.set(backgroundColor: .red)
        self.alertProgressView.size = .zero 
        self.addSubview(self.textView)
        self.addSubview(self.countView)
        self.countView.isHidden = true

        self.textView.minHeight = self.minHeight
        self.textView.growingDelegate = self
        self.addSubview(self.overlayButton)

        self.overlayButton.onTap { [unowned self] (tap) in
            if !self.textView.isFirstResponder {
                self.textView.becomeFirstResponder()
            }
        }

        let panRecognizer = UIPanGestureRecognizer { [unowned self] (recognizer) in
            self.onPanned?(recognizer)
        }
        panRecognizer.delegate = self
        self.overlayButton.addGestureRecognizer(panRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer { [unowned self] (recognizer) in
            self.handle(longPress: recognizer)
        }
        longPressRecognizer.delegate = self
        self.overlayButton.addGestureRecognizer(longPressRecognizer)

        self.layer.masksToBounds = true
        self.layer.borderWidth = Theme.borderWidth
        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.layer.cornerRadius = Theme.cornerRadius

        self.alertConfirmation.didCancel = { [unowned self] in
            self.resetAlertProgress()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let textViewWidth = self.width
        self.textView.size = CGSize(width: textViewWidth, height: self.textView.currentHeight)
        self.textView.left = 0
        self.textView.top = 0

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5

        self.alertProgressView.height = self.height

        self.overlayButton.frame = self.bounds
        self.blurView.frame = self.bounds

        self.layer.borderColor = self.messageContext.color.color.cgColor
    }

    func setPlaceholder(with channel: TCHChannel) {
        channel.getMembersAsUsers()
            .observeValue { (users) in
                runMain {
                    let notMeUsers = users.filter { (user) -> Bool in
                        return user.objectId != User.current()?.objectId
                    }

                    self.textView.setPlaceholder(for: notMeUsers)
                }
        }
    }

    private func handle(longPress: UILongPressGestureRecognizer) {

        switch longPress.state {
        case .possible:
            break
        case .began:
            self.startAlertAnimation()
        case .changed:
            break
        case .ended, .cancelled, .failed:
            self.endAlertAnimation()
        @unknown default:
            break
        }
    }

    private func startAlertAnimation() {
        self.messageContext = .emergency
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
            self.messageContext = .casual
            self.alertAnimator = UIViewPropertyAnimator(duration: 0.5,
                                                        curve: .linear,
                                                        animations: { [unowned self] in
                                                            self.alertProgressView.size = CGSize(width: 0, height: self.height)
                                                            self.layer.borderColor = self.messageContext.color.color.cgColor
            })
            self.alertAnimator?.startAnimation()
        }
    }

    func reset() {
        self.textView.text = String()
        self.textView.alpha = 1
        self.resetInputViews()
        self.resetAlertProgress()
        self.countView.isHidden = true 
    }

    func resetAlertProgress() {
        self.messageContext = .casual
        self.alertProgressView.width = 0
        self.alertProgressView.set(backgroundColor: .red)
        self.alertProgressView.alpha = 1
        self.resetInputViews()
        self.alertProgressView.layer.removeAllAnimations()
        self.layer.borderColor = self.messageContext.color.color.cgColor
    }

    func resetInputViews() {
        self.textView.inputAccessoryView = nil
        self.textView.reloadInputViews()
    }

    private func showAlertConfirmation() {
        self.alertConfirmation.frame = CGRect(x: 0,
                                              y: 0,
                                              width: UIScreen.main.bounds.width,
                                              height: 60)
        self.alertConfirmation.keyboardAppearance = self.textView.keyboardAppearance
        self.textView.inputAccessoryView = self.alertConfirmation
        self.textView.reloadInputViews()

        if let activeChannel = self.activeChannel {
            switch activeChannel.channelType {
            case .system(_):
                break
            case .pending(_):
                break 
            case .channel(let channel):
                channel.getMembersAsUsers()
                .observe(with: { (result) in
                    runMain {
                        switch result {
                        case .success(let users):
                            self.alertConfirmation.setAlertMessage(for: users)
                        case .failure(_):
                            break
                        }
                    }
                })
            }
        }

        self.alertProgressView.size = CGSize(width: self.width, height: self.height)
    }
}

extension MessageInputView: GrowingTextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {}

    func textViewTextDidChange(_ textView: GrowingTextView) {
        self.countView.udpate(with: self.textView.text.count, max: self.textView.maxLength)

        guard let channelDisplayable = ChannelSupplier.shared.activeChannel.value,
            self.textView.text.count > 0 else { return }

        switch channelDisplayable.channelType {
        case .system(_):
            break
        case .pending(_):
            break
        case .channel(let channel):
            // Twilio throttles this call to every 5 seconds
            channel.typing()
        }
    }

    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.textView.height = height
            self.height = height
            self.y = self.y + (self.oldTextViewHeight - height)
            self.layoutNow()
            self.oldTextViewHeight = height
        }
    }
}

extension MessageInputView: UIGestureRecognizerDelegate {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer {
            return self.textView.isFirstResponder
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        
        return true
    }
}

private class AlertProgressView: View {}
