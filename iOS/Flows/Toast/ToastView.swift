//
//  ToastView.swift
//  Ours
//
//  Created by Benji Dodgson on 5/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import GestureRecognizerClosures

enum ToastPosition {
    case top, bottom
}

enum ToastState {
    case hidden, present, left, expanded, alphaIn, dismiss, gone
}

class ToastView: View {

    private lazy var blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
    private lazy var blurView = UIVisualEffectView(effect: self.blurEffect)
    private lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: self.blurEffect)
    private lazy var vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
    private let titleLabel = Label(font: .regularBold)
    private let descriptionLabel = Label(font: .smallBold)
    private let imageView = DisplayableImageView()

    var didDismiss: () -> Void = {}
    var didTap: () -> Void = {}

    var toast: Toast?

    let revealAnimator = UIViewPropertyAnimator(duration: 0.35,
                                                dampingRatio: 0.6,
                                                animations: nil)

    let leftAnimator = UIViewPropertyAnimator(duration: 0.35,
                                              dampingRatio: 0.9,
                                              animations: nil)

    let expandAnimator = UIViewPropertyAnimator(duration: 0.35,
                                                dampingRatio: 0.9,
                                                animations: nil)

    let dismissAnimator = UIViewPropertyAnimator(duration: 0.35,
                                                 dampingRatio: 0.6,
                                                 animations: nil)

    private var panStart: CGPoint?
    private var startY: CGFloat?

    var maxHeight: CGFloat?
    var screenOffset: CGFloat = 50
    var presentationDuration: TimeInterval = 10.0
    //Used to present the toast from the top OR bottom of the screen
    private let position: ToastPosition = .top

    private var toastState = ToastState.hidden {
        didSet {
            if self.toastState != oldValue {
                self.updateFor(state: self.toastState)
            }
        }
    }

    private var title: Localized? {
        didSet {
            guard let text = self.title else { return }
            self.titleLabel.setText(text)
            self.layoutNow()
        }
    }

    private var descriptionText: Localized? {
        didSet {
            guard let text = self.descriptionText else { return }
            self.descriptionLabel.setText(text)
            self.layoutNow()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        guard let superview = UIWindow.topWindow() else { return }
        superview.addSubview(self)

        self.addSubview(self.blurView)
        self.addSubview(self.imageView)
        self.addSubview(self.descriptionLabel)
        self.vibrancyEffectView.contentView.addSubview(self.titleLabel)
        self.blurView.contentView.addSubview(self.vibrancyEffectView)

        self.isUserInteractionEnabled = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10

        self.imageView.layer.masksToBounds = true
        self.imageView.layer.cornerRadius = 5
        self.imageView.imageView.tintColor = Color.white.color
        self.imageView.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true

        self.descriptionLabel.alpha = 0
        self.titleLabel.alpha = 0

        self.showShadow(withOffset: 5)
        self.updateFor(state: self.toastState)

        if self.position == .top {
            self.screenOffset = superview.safeAreaInsets.top
        } else {
            self.screenOffset = superview.safeAreaInsets.bottom
        }
    }

    func configure(toast: Toast) {
        self.toast = toast
        self.title = toast.title
        self.descriptionText = localized(toast.description)

        self.onTap { [unowned self] (tap) in
            toast.didTap()
            self.dismiss()
        }

        self.imageView.displayable = toast.displayable
    }

    func reveal() {
        self.layoutNow()
        self.revealAnimator.stopAnimation(true)
        self.revealAnimator.addAnimations { [unowned self] in
            self.toastState = .present
        }

        self.revealAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.moveLeft()
            }
        })
        self.revealAnimator.startAnimation(afterDelay: 0.5)
    }

    private func moveLeft() {
        self.layoutNow()

        self.leftAnimator.stopAnimation(true)
        self.leftAnimator.addAnimations { [unowned self] in
            self.toastState = .left
        }

        self.leftAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.expand()
            }
        })
        self.leftAnimator.startAnimation()
    }

    private func expand() {
        self.layoutNow()

        self.expandAnimator.stopAnimation(true)
        self.expandAnimator.addAnimations { [unowned self] in
            self.toastState = .expanded
            self.layoutNow()
        }

        self.expandAnimator.addAnimations({ [unowned self] in
            self.toastState = .alphaIn
        }, delayFactor: 0.5)

        self.expandAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.addPan()
                delay(self.presentationDuration) {
                    if self.toastState != .gone {
                        self.dismiss()
                    }
                }
            }
        })

        self.expandAnimator.startAnimation(afterDelay: 0.2)
    }

    private func addPan() {
        let panRecognizer = UIPanGestureRecognizer { [unowned self] panRecognizer in
            self.handle(panRecognizer: panRecognizer)
        }
        self.addGestureRecognizer(panRecognizer)
    }

    func dismiss() {

        self.revealAnimator.stopAnimation(true)
        self.expandAnimator.stopAnimation(true)
        self.leftAnimator.stopAnimation(true)

        self.dismissAnimator.addAnimations{ [unowned self] in
            self.toastState = .dismiss
        }

        self.dismissAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.toastState = .gone
                self.didDismiss()
            }
        })
        self.dismissAnimator.startAnimation()
    }

    private func updateFor(state: ToastState) {
        guard let superView = UIWindow.topWindow() else { return }
        switch state {
        case .hidden:
            if self.position == .top {
                self.bottom = superView.top - self.screenOffset - superView.safeAreaInsets.top
            } else {
                self.top = superView.bottom + self.screenOffset + superView.safeAreaInsets.bottom
            }
            self.width =  (60 * 0.74) + (Theme.contentOffset)
            self.maxHeight = 84
            self.centerOnX()
        case .present:
            if self.position == .top {
                self.top = superView.top + self.screenOffset
            } else {
                self.bottom = superView.bottom - self.screenOffset
            }
        case .left:
            if UIScreen.main.isSmallerThan(screenSize: .tablet) {
                self.left = superView.width * 0.025
            } else {
                self.left = superView.width * 0.175
            }
        case .expanded:
            self.maxHeight = nil
            if UIScreen.main.isSmallerThan(screenSize: .tablet) {
                self.width = superView.width * 0.95
            } else {
                self.width = superView.width * Theme.iPadPortraitWidthRatio
            }
        case .alphaIn:
            self.descriptionLabel.alpha = 1
            self.titleLabel.alpha = 1
        case .dismiss, .gone:
            if self.position == .top {
                self.bottom = superView.top + 10
            } else {
                self.top = superView.bottom - 10
            }
        }

        self.layoutNow()
    }

    private func handle(panRecognizer: UIPanGestureRecognizer) {
        guard let superview = UIWindow.topWindow() else { return }

        switch panRecognizer.state {
        case .began:
            self.initializePanIfNeeded(panRecognizer: panRecognizer)
        case .changed:
            self.initializePanIfNeeded(panRecognizer: panRecognizer)

            if let panStart = self.panStart, let startY = self.startY {
                let delta = panStart.y + panRecognizer.translation(in: superview).y
                self.centerY = (startY...CGFloat.greatestFiniteMagnitude).clamp(delta + startY)
            }
        case .ended, .cancelled, .failed:
            // Ensure we don't respond the end of an untracked pan gesture
            let offset = superview.height - self.screenOffset * 0.5
            if self.top <= offset {
                self.dismiss()
            }
        case .possible:
            break
        @unknown default:
            break
        }
    }

    private func initializePanIfNeeded(panRecognizer: UIPanGestureRecognizer) {
        if self.panStart == nil, let superview = UIWindow.topWindow() {
            self.startY = self.centerY
            self.panStart = panRecognizer.translation(in: superview)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.vibrancyEffectView.expandToSuperviewSize()
        self.blurView.roundCorners()

        self.imageView.size = CGSize(width: 60 * 0.74, height: 60)
        self.imageView.left = Theme.contentOffset.half
        self.imageView.top = Theme.contentOffset.half

        let maxTitleWidth: CGFloat
        if UIScreen.main.isSmallerThan(screenSize: .tablet) {
            maxTitleWidth = self.width - (self.imageView.right + Theme.contentOffset)
        } else {
            maxTitleWidth = (self.width * Theme.iPadPortraitWidthRatio) - (self.imageView.right + 22)
        }

        self.titleLabel.setSize(withWidth: maxTitleWidth)
        self.titleLabel.match(.left, to: .right, of: self.imageView, offset: Theme.contentOffset.half)
        self.titleLabel.match(.top, to: .top, of: self.imageView)

        self.descriptionLabel.setSize(withWidth: maxTitleWidth)
        self.descriptionLabel.match(.left, to: .right, of: self.imageView, offset: Theme.contentOffset.half)
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: 4)
        if self.descriptionLabel.height > 84 {
            self.descriptionLabel.height = 84
        }

        if let height = self.maxHeight {
            self.height = height
        } else if self.descriptionLabel.bottom + Theme.contentOffset.half < 84 {
            self.height = 84
        } else {
            self.height = self.descriptionLabel.bottom + Theme.contentOffset.half
        }
    }
}
