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

    let leftAnimator = UIViewPropertyAnimator(duration: 0.35,
                                              dampingRatio: 0.9,
                                              animations: nil)

    let expandAnimator = UIViewPropertyAnimator(duration: 0.35,
                                                dampingRatio: 0.9,
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

        self.addSubview(self.vibrancyView)
        self.addSubview(self.imageView)
        self.addSubview(self.descriptionLabel)
        self.vibrancyView.effectView.contentView.addSubview(self.titleLabel)

        self.imageView.imageView.tintColor = Color.white.color

        self.descriptionLabel.alpha = 0
        self.titleLabel.alpha = 0

        self.descriptionText = localized(self.toast.description)
        self.title = self.toast.title
        self.imageView.displayable = self.toast.displayable
    }

    override func didReveal() {
        self.moveLeft()
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
                Task {
                    await Task.sleep(seconds: self.toast.duration)
                    if self.state != .gone {
                        self.dismiss()
                    } else {
                        await self.taskPool.cancelAndRemoveAll()
                    }

                }.add(to: self.taskPool)
            }
        })

        self.expandAnimator.startAnimation(afterDelay: 0.2)
    }

    override func dismiss() {
        super.dismiss()

        self.expandAnimator.stopAnimation(true)
        self.leftAnimator.stopAnimation(true)
    }

    override func update(for state: ToastState) {
        super.update(for: state)

        #if !NOTIFICATION
        guard let superView = UIWindow.topWindow() else { return }
        switch state {
        case .hidden:
            self.width =  (60 * 0.74) + (Theme.contentOffset)
            self.maxHeight = 84
            self.centerOnX()
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
        case .present, .dismiss, .gone:
            break 
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
        self.titleLabel.match(.left, to: .right, of: self.imageView, offset: .short)
        self.titleLabel.match(.top, to: .top, of: self.imageView)

        self.descriptionLabel.setSize(withWidth: maxTitleWidth)
        self.descriptionLabel.match(.left, to: .right, of: self.imageView, offset: .standard)
        self.descriptionLabel.match(.top, to: .bottom, of: self.titleLabel, offset: .short)
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
