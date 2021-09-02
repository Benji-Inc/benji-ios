//
//  ReadAllFooterView.swift
//  Benji
//
//  Created by Benji Dodgson on 5/17/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie
import Combine

class ReadAllFooterView: UICollectionReusableView {

    let animationView = AnimationView.with(animation: .loading)
    private let label = Label(font: .smallBold)
    var isAnimatingFinal: Bool = false
    private let minScale: CGFloat = 0.8
    
    private(set) var animator: UIViewPropertyAnimator?
    private var cancellables = Set<AnyCancellable>()
    var didCompleteAnimation: CompletionOptional = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    deinit {
        // Because this animator is interruptable and is stopped by the completion event of another animation, we need to ensure that this gets called before the animator is cleaned up when this view is deallocated because theres no guarantee that will happen before a user dismisses the screen
        self.animator?.stopAnimation(true)
    }

    private func initializeViews() {
        self.set(backgroundColor: .clear)
        self.addSubview(self.label)
        self.label.alpha = 0
        self.label.textAlignment = .center
        self.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        MessageSupplier.shared.$hasUnreadMessage.mainSink { [unowned self] (hasUnread) in
            self.configure(hasUnreadMessages: hasUnread)
        }.store(in: &self.cancellables)
    }

    func configure(hasUnreadMessages: Bool) {

        var text: Localized
        if hasUnreadMessages {
            text = "Read all? 🤓"
        } else {
            text = "You're up to date. 😄"
        }

        self.label.setText(text)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.pin(.top, padding: 20)
        self.label.centerOnX()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.match(.left, to: .right, of: self.label, offset: Theme.contentOffset)
        self.animationView.centerY = self.label.centerY
    }

    func createAnimator() {
        guard self.animator.isNil else { return }
        
        self.animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear, animations: { [weak self] in
            guard let `self` = self else { return }
            self.label.alpha = 1
            self.label.transform = .identity
        })

        self.animator?.addCompletion({ [weak self] (position) in
            guard let `self` = self else { return }
            // Animator completes initially on pause, so we also need to check progress
            if position == .end, let progress = self.animator?.fractionComplete, progress == 1.0 {
                self.didCompleteAnimation?()
            }
            self.animator = nil
        })

        self.animator?.scrubsLinearly = true
        self.animator?.isInterruptible = true
        self.animator?.pauseAnimation()
        self.prepareInitialAnimation()
    }

    //reset the animation
    private func prepareInitialAnimation() {
        self.isAnimatingFinal = false
        self.label.alpha = 0
        self.label.transform = CGAffineTransform.init(scaleX: self.minScale, y: self.minScale)
    }

    func stop() {
        if self.animator?.isRunning == true {
            self.animator?.stopAnimation(false)
        } else {
            self.animator = nil
        }

        self.isAnimatingFinal = false
        self.animationView.stop()
        self.prepareInitialAnimation()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.label.text = nil
        if let animator = self.animator, animator.isRunning {
            animator.stopAnimation(true)
            self.animator = nil 
        }
    }
}
