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

class ReadAllFooterView: UICollectionReusableView {

    let animationView = AnimationView(name: "loading")
    private let label = Label(font: .smallBold)
    var isAnimatingFinal: Bool = false
    var currentTransform: CGAffineTransform?
    private let minScale: CGFloat = 0.8
    
    private(set) var animator: UIViewPropertyAnimator?
    private var dragStartPosition: CGPoint = .zero
    private var fractionCompletedStart: CGFloat = 0

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
    }

    func configure(hasUnreadMessages: Bool, section: Int) {

        var text: Localized
        if hasUnreadMessages {
            text = "Read all? 🤓"
        } else {
            text = "You're up to date."
        }

        self.label.setText(text)
        self.prepareInitialAnimation()
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
        self.animator = UIViewPropertyAnimator(duration: 2.0, curve: .linear, animations: {
            self.label.alpha = 1
            self.label.transform = .identity
        })

        self.animator?.addCompletion({ (position) in
            self.animator = nil
            self.prepareInitialAnimation()
        })

        self.animator?.scrubsLinearly = true
        self.animator?.isInterruptible = true
    }

    //reset the animation
    func prepareInitialAnimation() {
        self.isAnimatingFinal = false
        self.label.alpha = 0
        self.label.transform = CGAffineTransform.init(scaleX: self.minScale, y: self.minScale)
    }

    //    func start(showLoading: Bool) {
    //        self.isAnimatingFinal = true
    //        if !self.animationView.isAnimationPlaying, showLoading {
    //            self.animationView.play()
    //        }
    //    }

    func stop() {
        self.isAnimatingFinal = false
        self.animationView.stop()
        self.prepareInitialAnimation()
    }

    //final animation to display loading
    func animateFinal() {
        //        if self.isAnimatingFinal {
        //            return
        //        }
        //        self.isAnimatingFinal = true
        //        UIView.animate(withDuration: Theme.animationDuration) {
        //            self.label.alpha = 1
        //            self.label.transform = .identity
        //        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.label.text = nil
    }
}
