//
//  ToastBannerView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import GestureRecognizerClosures

class ToastBannerView: ToastView {

    private let vibrancyView = VibrancyView()
    private let titleLabel = Label(font: .regularBold)
    private let descriptionLabel = Label(font: .smallBold)
    private let imageView = AvatarView()

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

        #if !NOTIFICATION
        guard let superview = UIWindow.topWindow() else { return }
        superview.addSubview(self)

        self.addSubview(self.vibrancyView)
        self.addSubview(self.imageView)
        self.addSubview(self.descriptionLabel)
        self.vibrancyView.effectView.contentView.addSubview(self.titleLabel)

        self.isUserInteractionEnabled = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10

        self.imageView.imageView.tintColor = Color.white.color

        self.descriptionLabel.alpha = 0
        self.titleLabel.alpha = 0

        if self.toast.position == .top {
            self.screenOffset = superview.safeAreaInsets.top
        } else {
            self.screenOffset = superview.safeAreaInsets.bottom
        }

        self.descriptionText = localized(self.toast.description)
        self.title = self.toast.title
        self.imageView.displayable = self.toast.displayable
        #endif

        self.layoutNow()
    }

    override func reveal() {
        super.reveal()

        self.layoutNow()
        self.revealAnimator.stopAnimation(true)
        self.revealAnimator.addAnimations { [unowned self] in
            self.state = .present
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
            self.state = .left
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
            self.state = .expanded
            self.layoutNow()
        }

        self.expandAnimator.addAnimations({ [unowned self] in
            self.state = .alphaIn
        }, delayFactor: 0.5)

        self.expandAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.addPan()
                delay(self.toast.duration) {
                    if self.state != .gone {
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

    override func dismiss() {
        super.dismiss()

        self.revealAnimator.stopAnimation(true)
        self.expandAnimator.stopAnimation(true)
        self.leftAnimator.stopAnimation(true)

        self.dismissAnimator.addAnimations{ [unowned self] in
            self.state = .dismiss
        }

        self.dismissAnimator.addCompletion({ [unowned self] (position) in
            if position == .end {
                self.state = .gone
                self.didDismiss()
            }
        })
        self.dismissAnimator.startAnimation()
    }

    override func update(for state: ToastState) {
        super.update(for: state)

        #if !NOTIFICATION
        guard let superView = UIWindow.topWindow() else { return }
        switch state {
        case .hidden:
            if self.toast.position == .top {
                self.bottom = superView.top - self.screenOffset - superView.safeAreaInsets.top
            } else {
                self.top = superView.bottom + self.screenOffset + superView.safeAreaInsets.bottom
            }
            self.width =  (60 * 0.74) + (Theme.contentOffset)
            self.maxHeight = 84
            self.centerOnX()
            self.layoutNow()
            self.didPrepareForPresentation()
        case .present:
            if self.toast.position == .top {
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
            if self.toast.position == .top {
                self.bottom = superView.top + 10
            } else {
                self.top = superView.bottom - 10
            }
        }
        #endif
        self.layoutNow()
    }

    private func handle(panRecognizer: UIPanGestureRecognizer) {
        #if !NOTIFICATION
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
        #endif
    }

    private func initializePanIfNeeded(panRecognizer: UIPanGestureRecognizer) {
        #if !NOTIFICATION
        if self.panStart == nil, let superview = UIWindow.topWindow() {
            self.startY = self.centerY
            self.panStart = panRecognizer.translation(in: superview)
        }
        #endif
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.vibrancyView.expandToSuperviewSize()
        self.vibrancyView.roundCorners()

        self.imageView.size = CGSize(width: 60 * 0.74, height: 60)
        self.imageView.left = Theme.contentOffset.half
        self.imageView.top = Theme.contentOffset.half

        if self.imageView.displayable is UIImage {
            self.imageView.layer.borderColor = Color.clear.color.cgColor
            self.imageView.layer.borderWidth = 0
            self.imageView.set(backgroundColor: .clear)
        }
        
        self.imageView.layer.masksToBounds = true
        self.imageView.layer.cornerRadius = 5
        self.imageView.clipsToBounds = true

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
