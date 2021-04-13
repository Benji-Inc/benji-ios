//
//  SwipeableInputAccessoryView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import TMROLocalization
import Combine

class SwipeableInputAccessoryView: View, AttachmentViewControllerDelegate, UIGestureRecognizerDelegate {

    static let preferredHeight: CGFloat = 54.0
    static let maxHeight: CGFloat = 200.0

    private(set) var previewAnimator: UIViewPropertyAnimator?
    private(set) var previewView: PreviewMessageView?
    private(set) var interactiveStartingPoint: CGPoint?

    var alertAnimator: UIViewPropertyAnimator?
    var selectionFeedback = UIImpactFeedbackGenerator(style: .rigid)
    var borderColor: CGColor? {
        didSet {
            self.inputContainerView.layer.borderColor = self.borderColor ?? Color.purple.color.cgColor
        }
    }

    let inputContainerView = View()
    let attachmentView = AttachmentView()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    lazy var textView = InputTextView(with: self)
    let animationView = AnimationView(name: "loading")
    let plusAnimationView = AnimationView(name: "plusToX")
    let overlayButton = UIButton()
    var cancellables = Set<AnyCancellable>()

    private(set) var inputLeadingContstaint: NSLayoutConstraint?
    private(set) var attachmentHeightAnchor: NSLayoutConstraint?

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: InputAccessoryView.preferredHeight)
    }

    override var intrinsicContentSize: CGSize {
        var newSize = self.bounds.size

        if self.textView.bounds.size.height > 0.0 {
            newSize.height = self.textView.bounds.size.height + 20.0
        }

        if let constraint = self.attachmentHeightAnchor, constraint.constant > 0 {
            newSize.height += self.attachmentView.height + 10
        }

        if newSize.height < InputAccessoryView.preferredHeight || newSize.height > 120.0 {
            newSize.height = InputAccessoryView.preferredHeight
        }

        if newSize.height > InputAccessoryView.maxHeight {
            newSize.height = InputAccessoryView.maxHeight
        }

        return newSize
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)

        self.addSubview(self.plusAnimationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .autoReverse

        self.addSubview(self.inputContainerView)
        self.inputContainerView.set(backgroundColor: .clear)

        self.inputContainerView.addSubview(self.blurView)

        self.inputContainerView.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.inputContainerView.addSubview(self.textView)
        self.inputContainerView.addSubview(self.attachmentView)
        self.inputContainerView.addSubview(self.overlayButton)

        self.inputContainerView.layer.masksToBounds = true
        self.inputContainerView.layer.borderWidth = Theme.borderWidth
        self.inputContainerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.inputContainerView.layer.cornerRadius = Theme.cornerRadius

        self.setupConstraints()
        self.setupGestures()
        self.setupHandlers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.overlayButton.expandToSuperviewSize()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.match(.right, to: .right, of: self.inputContainerView, offset: Theme.contentOffset)
        self.animationView.centerOnY()
    }

    // MARK: PRIVATE

    private func setupConstraints() {
        self.translatesAutoresizingMaskIntoConstraints = false

        let guide = self.layoutMarginsGuide

        self.plusAnimationView.translatesAutoresizingMaskIntoConstraints = false
        self.plusAnimationView.bottomAnchor.constraint(equalTo: self.textView.bottomAnchor).isActive = true
        self.plusAnimationView.heightAnchor.constraint(equalToConstant: 43).isActive = true
        self.plusAnimationView.widthAnchor.constraint(equalToConstant: 43).isActive = true
        self.plusAnimationView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true

        self.inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.inputContainerView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        self.inputContainerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -10).isActive = true

        let leadingConstant: CGFloat = self.shouldShowPlusButton() ? 53 : 0
        self.inputLeadingContstaint = self.inputContainerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: leadingConstant)
        self.inputLeadingContstaint?.isActive = true
        self.inputContainerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true

        self.attachmentView.leadingAnchor.constraint(equalTo: self.inputContainerView.leadingAnchor).isActive = true
        self.attachmentView.trailingAnchor.constraint(equalTo: self.inputContainerView.trailingAnchor).isActive = true
        self.attachmentView.topAnchor.constraint(equalTo: self.inputContainerView.topAnchor).isActive = true
        self.attachmentHeightAnchor = NSLayoutConstraint(item: self.attachmentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
        self.attachmentHeightAnchor?.isActive = true

        self.textView.leadingAnchor.constraint(equalTo: self.inputContainerView.leadingAnchor).isActive = true
        self.textView.trailingAnchor.constraint(equalTo: self.inputContainerView.trailingAnchor).isActive = true
        self.textView.topAnchor.constraint(equalTo: self.attachmentView.bottomAnchor).isActive = true
        self.textView.bottomAnchor.constraint(equalTo: self.inputContainerView.bottomAnchor).isActive = true
        self.textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private func setupHandlers() {

        KeyboardManger.shared.$currentEvent
            .mainSink { event in
            switch event {
            case .didHide(_):
                self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
                self.plusAnimationView.play(toProgress: 0.0)
            case .didShow(_):
                break
            default:
                break
            }
        }.store(in: &self.cancellables)

        self.textView.textDidUpdate = { [unowned self] text in
            self.handleTextChange(text)
        }

        self.overlayButton.didSelect { [unowned self] in
            if !self.textView.isFirstResponder {
                self.textView.becomeFirstResponder()
            }
        }

        self.plusAnimationView.didSelect { [unowned self] in
            self.updateInputType()
        }

        self.textView.confirmationView.button.didSelect { [unowned self] in
            self.didPressAlertCancel()
        }

        self.attachmentView.$messageKind.mainSink { (kind) in
            self.attachentViewDidUpdate(kind: kind)
        }.store(in: &self.cancellables)
    }

    // MARK: OVERRIDES

    func shouldShowPlusButton() -> Bool {
        return true
    }

    func setupGestures() {
        let panRecognizer = UIPanGestureRecognizer { [unowned self] (recognizer) in
            self.handle(pan: recognizer)
        }
        panRecognizer.delegate = self
        self.overlayButton.addGestureRecognizer(panRecognizer)
    }

    func attachentViewDidUpdate(kind: MessageKind?) {
        self.attachmentHeightAnchor?.constant = kind.isNil ? 0 : 100
        self.layoutNow()
    }

    func didPressAlertCancel() {}

    func handleTextChange(_ text: String) {
        self.animateInputViews(with: text)
    }

    func updateInputType() {}

    func animateInputViews(with text: String) {}

    func reset() {
        self.textView.reset()
        self.textView.alpha = 1
        self.attachmentView.alpha = 1
        self.attachmentView.configure(with: nil)
        self.attachmentView.messageKind = nil
        self.textView.countView.isHidden = true
    }

    func attachementView(_ controller: AttachmentViewController, didSelect attachment: Attachment) {}

    func shouldHandlePan() -> Bool {
        return true
    }

    func panDidBegin() {

    }

    func previewAnimatorDidEnd() {
        self.reset()
        self.previewView?.removeFromSuperview()
    }

    func handle(pan: UIPanGestureRecognizer) {
        guard self.shouldHandlePan() else { return }

        let currentLocation = pan.location(in: nil)
        let startingPoint: CGPoint

        if let point = self.interactiveStartingPoint {
            startingPoint = point
        } else {
            // Initial location
            startingPoint = pan.location(in: nil)
            self.interactiveStartingPoint = startingPoint
        }

        let totalOffset: CGFloat = clamp(self.halfHeight, InputAccessoryView.preferredHeight, InputAccessoryView.maxHeight * 0.5)
        var diff = (startingPoint.y - currentLocation.y)
        diff -= totalOffset
        var progress = diff / 100
        progress = clamp(progress, 0.0, 1.0)

        switch pan.state {
        case .possible:
            break
        case .began:
            self.previewView = PreviewMessageView()
            self.panDidBegin()
            self.previewView?.backgroundView.alpha = 0.0
            self.addSubview(self.previewView!)
            self.previewView?.frame = self.inputContainerView.frame
            self.previewView?.layoutNow()
            let top = self.top - totalOffset

            self.previewAnimator = UIViewPropertyAnimator(duration: Theme.animationDuration,
                                                          curve: .easeInOut,
                                                          animations: nil)
            self.previewAnimator?.addAnimations {
                UIView.animateKeyframes(withDuration: 0,
                                        delay: 0,
                                        animations: {
                                            UIView.addKeyframe(withRelativeStartTime: 0,
                                                               relativeDuration: 0.3,
                                                               animations: {
                                                                self.attachmentView.alpha = 0
                                                                self.textView.alpha = 0
                                                                self.previewView?.backgroundView.alpha = 1
                                            })

                                            UIView.addKeyframe(withRelativeStartTime: 0,
                                                               relativeDuration: 1,
                                                               animations: {
                                                                self.previewView?.top = top
                                                                self.setNeedsLayout()
                                            })

                }) { (completed) in }
            }

            self.previewAnimator?.addCompletion({ (position) in
                if position == .end {
                    self.previewAnimatorDidEnd()
                }
                if position == .start {
                    self.previewView?.removeFromSuperview()
                }

                self.selectionFeedback.impactOccurred()
                self.interactiveStartingPoint = nil
            })

            self.previewAnimator?.pauseAnimation()

        case .changed:
            if let preview = self.previewView {
                let translation = pan.translation(in: preview)
                preview.x = self.x + translation.x
                self.previewAnimator?.fractionComplete = (translation.y * -1) / 100
            }
        case .ended:
            self.previewAnimator?.isReversed = progress <= 0.02
            self.previewAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        case .cancelled:
            self.previewAnimator?.finishAnimation(at: .end)
        case .failed:
            self.previewAnimator?.finishAnimation(at: .end)
        @unknown default:
            break
        }
    }

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

